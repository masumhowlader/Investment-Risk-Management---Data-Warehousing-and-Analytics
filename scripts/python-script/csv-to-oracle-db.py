import os
import pandas as pd
import cx_Oracle

# Configuration
CSV_DIRECTORY = '../csv-files'  # Directory containing CSV files
#CSV_DIRECTORY = '.'
ORACLE_CONNECTION_STRING = 'inv_risk_mgmt_source/i@localhost:1521/xepdb1'  # Oracle connection string

def detect_boolean_columns(df):
    """
    Detect columns that contain only TRUE, FALSE, or empty values.
    """
    boolean_columns = []
    for col in df.columns:
        unique_values = df[col].dropna().unique()
        if (len(unique_values) > 0 and set(unique_values).issubset({'TRUE', 'FALSE'})):
            boolean_columns.append(col)
    return boolean_columns

def transform_boolean_columns(df, boolean_columns):
    """
    Transform boolean columns (TRUE/FALSE/NULL) to numeric (1/0/NULL):
    - TRUE -> 1
    - FALSE -> 0
    - NULL -> NULL
    """
    for col in boolean_columns:
        df[col] = df[col].replace({
            'TRUE': 1,
            'FALSE': 0,
            None: None,
            '': None
        }).astype('Int64')  # Uses pandas' nullable integer type
    return df

def get_table_metadata(connection, table_name):
    """
    Fetch column names and data types for a given table from Oracle metadata.
    """
    cursor = connection.cursor()
    query = """
        SELECT COLUMN_NAME, DATA_TYPE
        FROM ALL_TAB_COLUMNS
        WHERE TABLE_NAME = :table_name
        ORDER BY COLUMN_ID
    """
    try:
        cursor.execute(query, {'table_name': f'SRC_{table_name.upper()}'})
        metadata = {row[0]: row[1] for row in cursor.fetchall()}
        return metadata
    finally:
        cursor.close()

def map_oracle_to_pandas_dtype(oracle_type):
    """
    Map Oracle data types to Pandas data types.
    """
    if oracle_type in ['NUMBER', 'FLOAT']:
        return float
    elif oracle_type in ['VARCHAR2', 'CHAR', 'NVARCHAR2', 'NCHAR']:
        return str
    elif oracle_type == 'DATE':
        return 'object'  # Dates will be handled separately during cleaning
    else:
        return str  # Default to string for unsupported types

def clean_data(df, metadata, boolean_columns):
    """
    Clean the DataFrame with proper date handling:
    1. First try parsing dates in M/D/YYYY format
    2. Explicitly handle null/empty date values
    3. Then handle other data types
    """
    # Transform boolean columns
    df = transform_boolean_columns(df, boolean_columns)
    
    for col in df.columns:
        if col in metadata:
            data_type = metadata[col]

            if data_type == 'DATE':
                try:
                    # Convert empty strings to None first
                    df[col] = df[col].replace(r'^\s*$', None, regex=True)
                    
                    # Parse with month first (M/D/YYYY), leaving None values as None
                    dates = pd.to_datetime(df[col], format='%m/%d/%Y', errors='coerce')
                    
                    # Replace invalid dates (NaT) with None
                    df[col] = dates.where(dates.notna(), None)
                except Exception as e:
                    print(f"Warning: Date parsing failed for column {col}: {str(e)}")
            elif data_type == 'NUMBER':
                # Convert empty strings to None first
                df[col] = df[col].replace(r'^\s*$', None, regex=True)
                
                # Handle numeric conversion
                df[col] = pd.to_numeric(df[col], errors='coerce')
                df[col] = df[col].fillna(0).astype(int)
            elif data_type in ['VARCHAR2', 'CHAR']:
                # Convert empty strings to None first
                df[col] = df[col].replace(r'^\s*$', None, regex=True)
                df[col] = df[col].fillna('').astype(str)
                # Handle string conversion
                df[col] = df[col].astype(str).str.strip()
        else:
            print(f"Warning: Column '{col}' not found in metadata. Skipping.")
    
    return df

def truncate_table(connection, table_name):
    """
    Truncate the specified table before loading data.
    """
    cursor = connection.cursor()
    try:
        print(f"Truncating table SRC_{table_name}...")
        cursor.execute(f"TRUNCATE TABLE SRC_{table_name}")
        connection.commit()
        print(f"Successfully truncated table SRC_{table_name}.")
    except Exception as e:
        print(f"Error truncating table SRC_{table_name}: {str(e)}")
    finally:
        cursor.close()

def upload_to_oracle(df, table_name, connection, chunk_size=50000):
    cursor = connection.cursor()
    try:
        # Prepare the base SQL once
        columns = ','.join(df.columns)
        placeholders = ','.join([f':{i+1}' for i in range(len(df.columns))])
        sql = f"INSERT INTO SRC_{table_name} ({columns}) VALUES ({placeholders})"
        
        # Process in chunks
        for chunk_start in range(0, len(df), chunk_size):
            chunk_end = min(chunk_start + chunk_size, len(df))
            chunk = df.iloc[chunk_start:chunk_end]
            
            # Prepare all rows in the chunk
            all_rows = []
            for _, row in chunk.iterrows():
                row_values = []
                for value in row:
                    if pd.isna(value) or value is None:
                        row_values.append(None)
                    elif isinstance(value, pd.Timestamp):
                        row_values.append(value.strftime('%d-%b-%Y').upper())
                    else:
                        row_values.append(value)
                all_rows.append(tuple(row_values))
            
            # Insert the entire chunk at once
            cursor.executemany(sql, all_rows)
            connection.commit()
            print(f"✓ Uploaded rows {chunk_start+1}-{chunk_end} to {table_name}")
        
        print(f"Successfully uploaded {len(df)} rows to {table_name}")
    except Exception as e:
        connection.rollback()
        error_msg = str(e).split('\n')[0]
        print(f"Error uploading to {table_name}: {error_msg}")
        if 'all_rows' in locals():
            print("Problematic chunk:", chunk_start+1, "-", chunk_end)
    finally:
        cursor.close()

def execute_procedures(connection):
    """
    Execute two stored procedures after data loading.
    """
    cursor = connection.cursor()
    try:
        # Procedure 1
        print("Executing procedure LOAD_STAGING_SCHEMA...")
        cursor.callproc("LOAD_STG_SCHEMA")  # Replace with the actual procedure name
        
        # Procedure 2
        print("Executing procedure LOAD_STAR_SCHEMA...")
        cursor.callproc("LOAD_STAR_SCHEMA")  # Replace with the actual procedure name
        
        # Commit if necessary
        connection.commit()
        print("Successfully executed both procedures.")
    except Exception as e:
        connection.rollback()
        print(f"Error executing procedures: {str(e)}")
    finally:
        cursor.close()

# Main script
def main():
    # Connect to Oracle
    try:
        connection = cx_Oracle.connect(ORACLE_CONNECTION_STRING)
        print("Connected to the Oracle database!")
    except Exception as e:
        print(f"Error connecting to Oracle: {e}")
        return

    # Process each CSV file in the directory
    for filename in os.listdir(CSV_DIRECTORY):
        if filename.endswith('.csv'):
            file_path = os.path.join(CSV_DIRECTORY, filename)
            table_name = filename.replace('.csv', '').upper()

            try:
                # Fetch metadata for the table
                metadata = get_table_metadata(connection, table_name)
                if not metadata:
                    print(f"Skipping file '{filename}': No metadata found for table SRC_{table_name}")
                    continue

                # Truncate the table before loading data
                truncate_table(connection, table_name)

                # Read the first chunk to detect boolean columns
                first_chunk = pd.read_csv(file_path, encoding='latin-1', nrows=1000, dtype=str)
                boolean_columns = detect_boolean_columns(first_chunk)
                
                # Update metadata to treat boolean columns as NUMBER(1)
                for col in boolean_columns:
                    if col in metadata:
                        metadata[col] = 'NUMBER'

                # Map Oracle data types to Pandas data types
                dtype_mapping = {col: map_oracle_to_pandas_dtype(data_type) for col, data_type in metadata.items()}

                # Read and process CSV in chunks
                chunk_iter = pd.read_csv(
                    file_path,
                    encoding='latin-1',
                    chunksize=50000,
                    dtype=dtype_mapping
                )
                
                for i, chunk in enumerate(chunk_iter):
                    print(f"Processing chunk {i+1} of {filename}")
                    
                    # Detect and transform boolean columns
                    chunk = transform_boolean_columns(chunk, boolean_columns)
                    
                    # Clean data
                    cleaned_chunk = clean_data(chunk, metadata, boolean_columns)
                    print(cleaned_chunk.head(2))  # Print sample of cleaned data
                    
                    # Upload data to Oracle
                    upload_to_oracle(cleaned_chunk, table_name, connection)
                
                print(f"Finished processing {filename}")
            except Exception as e:
                print(f"Error processing file '{filename}': {e}")
    
    # Execute stored procedures after loading all data
    try:
        #execute_procedures(connection)
        print("Not executing stored procedures...")
    except Exception as e:
        print(f"Error executing procedures: {e}")

    # Close Oracle connection
    connection.close()
    print("Oracle connection closed.")

# Run the script
if __name__ == '__main__':
    main()