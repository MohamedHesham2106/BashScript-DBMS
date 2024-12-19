#!/bin/bash

BASE_PATH="$HOME/DBMS/Databases"
mkdir -p "$BASE_PATH"

# Utils

function get_regex() {
    case $1 in
    CREATE)
        if [[ $2 =~ ^CREATE\ TABLE\ ([a-zA-Z0-9_]+)\ \((.*)\)[[:space:]]*(;)?$ ]]; then
            return 1
        else
            return 0
        fi
        ;;
    INSERT)
        if [[ $2 =~ ^INSERT\ INTO\ ([a-zA-Z0-9_]+)\ \(([a-zA-Z0-9_,[:space:]]+)\)\ VALUES\ \(([^\)]+)\)*\;?$ ]]; then
            return 1
        else
            return 0
        fi
        ;;
    SELECT)
        if [[ $2 =~ ^SELECT[[:space:]]+(\*|[a-zA-Z_][a-zA-Z0-9_]*(,[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*)*)[[:space:]]+FROM[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\;?$ ]]; then
            return 1
        else
            return 0
        fi
        ;;
    UPDATE)
        if [[ $2 =~ ^UPDATE[[:space:]]+([a-zA-Z0-9_]+)[[:space:]]+SET[[:space:]]+(.+)[[:space:]]+WHERE[[:space:]]+(.+)$ ]]; then
            return 1
        else
            return 0
        fi
        ;;
    DELETE)
        if [[ $2 =~ ^DELETE[[:space:]]+FROM[[:space:]]+([a-zA-Z0-9_]+)[[:space:]]+WHERE[[:space:]]+(.+)([[:space:]]*;)?$ ]]; then
            return 1
        else
            return 0
        fi
        ;;
    *)
        return 0
        ;;
    esac
}

# Database Related Fns

#CREATE DATABASE
function create_database() {

    read -p "Enter Database Name: " db_name
    if [ -d "$BASE_PATH/$db_name" ]; then
        echo "Database Already Exists."
    else
        mkdir "$BASE_PATH/$db_name"
        echo "Database Creation Succeded"
    fi
    read -p "Press any key to continue..."
    clear
}

#LIST DATABASE
function list_databases() {

    echo "Databases:"
    if [ -z "$(ls -A "$BASE_PATH")" ]; then
        echo "No Databases Created Yet"
    else
        ls "$BASE_PATH"
    fi
    read -p "Press any key to continue..."
    clear
}

#CONNECT TO DATABASE
function connect_database() {
    read -p "Enter database name: " db_name

    DB_PATH="$BASE_PATH/$db_name"

    if [[ -z "$db_name" ]]; then
        echo -e "\033[0;31mDatabase name cannot be empty.\033[0m"
        sleep 2s
        clear
        return
    fi

    if [[ ! -d "$DB_PATH" ]]; then
        echo -e "\033[0;31mDatabase '$db_name' does not exist.\033[0m"
        sleep 4s
        clear
        return
    else
        cd "$DB_PATH" || return
        table_menu "$DB_PATH"
        cd - || return
    fi

    clear
}

#DROP DATABASE
function drop_database() {

    read -p "Enter Database Name to Delete: " db_name

    if [ ! -d "$BASE_PATH/$db_name" ]; then
        echo -e "\033[0;31mDatabase does not exist.\033[0m"
    else
        read -p "Are you sure you want to delete '$db_name'? (y/yes/no/n): " bool
        bool=$(echo "$bool" | awk '{print tolower($0)}')

        if [[ "$bool" == "yes" || "$bool" == "y" ]]; then
            rm -r "$BASE_PATH/$db_name"
            clear
            echo "Database '$db_name' dropped."
        else
            clear
            echo "Database drop operation cancelled."
            main
        fi
    fi

}

# Table Related Fns

# TABLE MENU

function table_menu() {
    DB_DIR=$1
    echo "Here are the commands you can use:"
    echo "1. CREATE TABLE <table_name> (<column1>:<type>, <column2>:<type>, ...)"
    echo "   Example: CREATE TABLE users (id:INTEGER PRIMARY KEY, name:TEXT, salary:FLOAT, dob:DATE)"
    echo -e "   \033[0;31mSupported Datatypes: INTEGER, TEXT, FLOAT, DATE(YYYY-MM-DD) format only.\033[0m"
    echo ""
    echo "2. INSERT INTO <table_name> VALUES (<value1>, <value2>, ...)"
    echo "   Example: INSERT INTO users VALUES (Alice, 30, ...)"
    echo ""
    echo "3. SELECT ALL FROM <table_name>"
    echo "   Example: SELECT * FROM users"
    echo ""
    echo "4. SELECT <columns> FROM <table_name>"
    echo "   Example: SELECT name, age FROM users"
    echo ""
    echo "5. UPDATE <table_name> SET <column1=value1, column2=value2, ...> WHERE <condition>"
    echo "   Example: UPDATE users SET name=Bob, age=25 WHERE id=1"
    echo ""
    echo "6. Go back to the main menu"
    echo "   Type 'EXIT' to exit main menu"
    echo ""
    while true; do
        read -p "SQL> " sql_query

        # Check for the command type based on the input
        case "$sql_query" in
        CREATE\ TABLE*) create_table "$sql_query" ;;
        INSERT\ INTO*) insert_into_table "$sql_query" ;;
        SELECT\ *\ FROM\ *) select_from_table "$sql_query" ;;
        UPDATE*) update_table "$sql_query" ;;
        DELETE*) delete_from_table "$sql_query" ;;
        EXIT) main_menu ;;
        *) echo "Invalid command. Please try again." ;;
        esac
    done
}

#CREATE TABLES

function create_table() {
    create_command=$1

    # regex to validate the CREATE TABLE command
    get_regex CREATE "$create_command"
    if [ $? -eq 1 ]; then
        table_name="${BASH_REMATCH[1]}"
        schema="${BASH_REMATCH[2]}"

        # Check if the table already exists
        table_dir="$DB_DIR/$table_name"
        if [ -d "$table_dir" ]; then
            echo "Error: Table '$table_name' already exists."
            return
        fi

        fields=()
        datatypes=()
        primary_key=""

        # Parse fields and datatypes
        IFS=',' read -ra columns <<<"$schema"
        for column in "${columns[@]}"; do
            # Trim spaces around field:type
            column=$(echo "$column" | xargs)
            field=$(echo "$column" | cut -d':' -f1 | xargs)
            datatype=$(echo "$column" | cut -d':' -f2 | xargs)

            # Check if field or datatype is empty
            if [[ -z "$field" || -z "$datatype" ]]; then
                echo "Error: Each field must have a name and a datatype."
                return
            fi

            # Check for PRIMARY KEY in the datatype
            if [[ "$datatype" =~ PRIMARY\ KEY$ ]]; then
                datatype=$(echo "$datatype" | sed 's/PRIMARY KEY//g' | xargs) # Remove PRIMARY KEY
                if [[ -n "$primary_key" ]]; then
                    echo "Error: Only one primary key is allowed."
                    return
                fi
                primary_key="$field"
            fi

            # Validate datatype
            if [[ ! "$datatype" =~ ^(INTEGER|FLOAT|TEXT|DATE)$ ]]; then
                echo "Error: Invalid datatype '$datatype'. Supported types: INTEGER, FLOAT, TEXT, DATE, VARCHAR(n)."
                return
            fi

            # Check for duplicate fields
            if [[ " ${fields[@]} " =~ " $field " ]]; then
                echo "Error: Duplicate field name '$field'."
                return
            fi

            fields+=("$field")
            datatypes+=("$datatype")
        done

        # Ask for primary key if not specified in the schema
        if [[ -z "$primary_key" ]]; then
            echo "Fields: ${fields[*]}"
            read -p "Enter the primary key field: " primary_key

            if [[ ! " ${fields[@]} " =~ " $primary_key " ]]; then
                echo "Error: Primary key must be one of the fields."
                return
            fi
        fi

        # create the table directory and metadata file
        mkdir "$table_dir"
        table_meta_file="$table_dir/$table_name.meta"
        table_data_file="$table_dir/$table_name.txt"

        # Write metadata to the .meta file
        {
            echo "Fields: ${fields[*]}"
            echo "Datatypes: ${datatypes[*]}"
            echo "PrimaryKey: $primary_key"
        } >"$table_meta_file"

        # Write the column headers to the .txt file
        echo "${fields[*]}" >"$table_data_file"

        echo "Table '$table_name' created successfully."
    else
        echo "Invalid CREATE TABLE command. Ensure the format is: CREATE TABLE tablename (field:type, ...)."
    fi
}

#INSERT

function insert_into_table() {
    sql_query=$1

    # regex helper to validate the INSERT INTO command
    get_regex INSERT "$sql_query"
    if [ $? -eq 1 ]; then
        table_name="${BASH_REMATCH[1]}"
        columns="${BASH_REMATCH[2]}"
        values="${BASH_REMATCH[3]}"

        table_directory="$DB_DIR/$table_name"
        table_meta="$table_directory/$table_name.meta"
        table_data="$table_directory/$table_name.txt"

        # Check if the table exists
        if [ ! -f "$table_meta" ] || [ ! -f "$table_data" ]; then
            echo "Error: Table '$table_name' does not exist."
            return
        fi

        # getting fields, datatypes, and primary key from the table metadata
        fields=($(grep "Fields:" "$table_meta" | cut -d' ' -f2-))
        datatypes=($(grep "Datatypes:" "$table_meta" | cut -d' ' -f2-))
        primary_key=$(grep "PrimaryKey:" "$table_meta" | cut -d' ' -f2)

        # cols and values to be inserted
        IFS=', ' read -ra column_names <<<"$columns"
        IFS=', ' read -ra input_values <<<"$values"

        # remove leading/trailing whitespaces from column names and values
        for i in "${!column_names[@]}"; do
            column_names[$i]=$(echo "${column_names[$i]}" | xargs)
        done
        for i in "${!input_values[@]}"; do
            input_values[$i]=$(echo "${input_values[$i]}" | xargs)
        done

        # number of columns and values must match
        if [ "${#column_names[@]}" -ne "${#input_values[@]}" ]; then
            echo "Error: Number of columns does not match the number of values."
            return
        fi

        # make sure the columns exist in the table and validate the values
        for i in "${!column_names[@]}"; do
            column="${column_names[$i]}"
            field_index=-1
            # check if the column exists in the table
            for j in "${!fields[@]}"; do
                if [[ "${fields[$j]}" == "$column" ]]; then
                    field_index=$j
                    break
                fi
            done

            if [ "$field_index" -eq -1 ]; then
                echo "Error: Column '$column' does not exist in the table."
                return
            fi

            datatype="${datatypes[$field_index]}"
            value="${input_values[$i]}"

            # can edit this to handle more data types later
            case "$datatype" in
            INTEGER)
                if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
                    echo "Error: Value '$value' is not a valid INTEGER for column '$column'. Please re-enter the query with a valid integer."
                    return
                fi
                ;;
            FLOAT)
                if ! [[ "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
                    echo "Error: Value '$value' is not a valid FLOAT for column '$column'."
                    return
                fi
                ;;
            TEXT)
                # add single quotes around the value if not already present
                if [[ ! "$value" =~ ^\'[^\']*\'$ ]]; then
                    value="'$value'"
                fi
                ;;
            DATE)
                # DATE values must follow the format YYYY-MM-DD
                if ! [[ "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                    echo "Error: Value '$value' is not a valid DATE (must be in YYYY-MM-DD format) for column '$column'."
                    return
                fi
                ;;
            *)
                echo "Error: Unknown datatype '$datatype' for column '$column'."
                return
                ;;
            esac
        done

        # Check if primary key is provided and is unique
        pk_index=-1
        for i in "${!column_names[@]}"; do
            if [[ "${column_names[$i]}" == "$primary_key" ]]; then
                pk_index=$i
                break
            fi
        done

        # No primary key provided
        if [ "$pk_index" -eq -1 ]; then
            echo "Error: Primary key '$primary_key' is not provided. Please enter a value for the primary key."
            return
        fi

        pk_value="${input_values[$pk_index]}"

        # if already exist before
        if grep -q "^$pk_value " "$table_data"; then
            echo "Error: Primary key '$pk_value' already exists. Please enter a unique primary key."
            return
        fi

        # if a col isnt provided, set it to NULL
        row=()
        for i in "${!fields[@]}"; do
            field="${fields[$i]}"
            datatype="${datatypes[$i]}"
            value="${input_values[$i]}"

            # If a field is missing, set it to NULL
            if [ -z "$value" ]; then
                value="NULL"
            fi

            # Add the value to the row
            row+=("$value")
        done

        # just redirect the row to the table data file
        echo "${row[@]}" >>"$table_data"
        echo "Data inserted successfully with Primary Key: $pk_value"
    else
        echo "Invalid INSERT INTO command. Ensure the format is: INSERT INTO tablename (col1, col2, ...) VALUES (value1, value2, ...)"
    fi
}

#Select From Table
function select_from_table() {

    sql_query=$1

    # regex helper to validate the SELECT command
    get_regex SELECT "$sql_query"
    if [[ $? -eq 1 ]]; then
        # Extract columns and table name
        columns="${BASH_REMATCH[1]}"
        table_name="${BASH_REMATCH[3]}"
    else
        echo "Invalid SELECT command. Ensure the format is: SELECT <columns> FROM <table> or SELECT * FROM <table>"
        return
    fi

    table_directory="$DB_DIR/$table_name"
    table_meta="$table_directory/$table_name.meta"
    table_data="$table_directory/$table_name.txt"

    # does the table exist?
    if [ ! -f "$table_meta" ] || [ ! -f "$table_data" ]; then
        echo "Error: Table '$table_name' does not exist."
        return
    fi

    # get the fields from the table metadata
    fields=($(grep "Fields:" "$table_meta" | cut -d' ' -f2-))

    # is it SELECT * or specific columns?
    if [[ "$columns" == "*" ]]; then
        # If * is used, select all columns
        selected_columns=("${fields[@]}")
    else
        # cols is a comma-separated list of column names
        IFS=', ' read -ra selected_columns <<<"$columns"

        # make sure the columns exist in the table
        for col in "${selected_columns[@]}"; do
            if [[ ! " ${fields[@]} " =~ " $col " ]]; then
                echo "Error: Column '$col' does not exist in table '$table_name'."
                return
            fi
        done
    fi

    # Extract rows from the table data file
    while IFS=',' read -r line; do
        IFS=' ' read -ra row_data <<<"$line"
        output=""

        # Get the selected columns from the row
        for col in "${selected_columns[@]}"; do
            # Get the index of the column in the fields array
            index=$(echo "${fields[@]}" | tr ' ' '\n' | grep -n -w "$col" | cut -d: -f1)
            output+="${row_data[$((index - 1))]} "
        done

        # print the rows
        echo "$output"
    done <"$table_data" | column -t -s ' '
}

#UPDATE TABLE
function update_table() {
    sql_query=$1

    # regex helper to validate the UPDATE command
    get_regex UPDATE "$sql_query"
    if [[ $? -eq 1 ]]; then
        table_name="${BASH_REMATCH[1]}"
        set_values="${BASH_REMATCH[2]}"
        where_clause="${BASH_REMATCH[3]}"
    else
        echo "Invalid UPDATE command. Ensure the format is: UPDATE <table> SET <col1=value1, col2=value2, ...> WHERE <condition>"
        return
    fi

    table_directory="$DB_DIR/$table_name"
    table_meta="$table_directory/$table_name.meta"
    table_data="$table_directory/$table_name.txt"

    # Check if the table exists
    if [ ! -f "$table_meta" ] || [ ! -f "$table_data" ]; then
        echo "Error: Table '$table_name' does not exist."
        return
    fi

    # Get the fields from the table metadata
    fields=($(grep "Fields:" "$table_meta" | cut -d' ' -f2-))

    # place the set values in an array
    IFS=',' read -ra set_pairs <<<"$set_values"
    set_keys=()
    set_values=()
    for pair in "${set_pairs[@]}"; do
        key=$(echo "$pair" | cut -d'=' -f1 | xargs)
        value=$(echo "$pair" | cut -d'=' -f2 | xargs | sed "s/^'\(.*\)'$/\1/") # Remove quotes
        set_keys+=("$key")
        set_values+=("$value")
    done

    # get where column and value
    where_column=$(echo "$where_clause" | cut -d'=' -f1 | xargs)
    where_value=$(echo "$where_clause" | cut -d'=' -f2 | xargs | sed "s/^'\(.*\)'$/\1/" | sed 's/;$//') # remove quotes and semicolon
    where_index=$(echo "${fields[@]}" | tr ' ' '\n' | grep -n -w "$where_column" | cut -d: -f1)

    # check if the where column exists in the table
    if [[ -z "$where_index" ]]; then
        echo "Error: Column '$where_column' does not exist in table '$table_name'."
        return
    fi

    # loop through the set keys and check if they exist in the table
    for key in "${set_keys[@]}"; do
        set_index=$(echo "${fields[@]}" | tr ' ' '\n' | grep -n -w "$key" | cut -d: -f1)
        if [[ -z "$set_index" ]]; then
            echo "Error: Column '$key' does not exist in table '$table_name'."
            return
        fi
    done

    # mktemp to create a temporary file
    # then loop through the table data file
    temp_file=$(mktemp)

    if [[ ! -f "$temp_file" ]]; then
        echo "Error: Unable to create temporary file."
        return
    fi
    updated=false
    while IFS= read -r line; do
        # separate the row data into an array using space as the delimiter
        IFS=' ' read -ra row_data <<<"$line"

        # skip row 1 if it is the header
        if [[ "${row_data[*]}" == "${fields[*]}" ]]; then
            echo "$line" >>"$temp_file"
            continue
        fi

        # make sure the where condition matches
        if [[ "${row_data[$((where_index - 1))]}" == "$where_value" ]]; then
            updated=true
            # loop through the set keys and update the row data
            for i in "${!set_keys[@]}"; do
                set_key="${set_keys[$i]}"
                set_value="${set_values[$i]}"
                set_index=$(echo "${fields[@]}" | tr ' ' '\n' | grep -n -w "$set_key" | cut -d: -f1)
                row_data[$((set_index - 1))]="$set_value"
            done
        fi

        # Write the updated or unchanged row to the temp file
        echo "${row_data[*]}" >>"$temp_file"
    done <"$table_data"

    if $updated; then
        mv "$temp_file" "$table_data"
        echo "Table '$table_name' updated successfully."
    else
        rm "$temp_file"
        echo "No rows matched the WHERE clause."
    fi
}

#DELETE FROM TABLE
function delete_from_table() {
    sql_query=$1

    # regex helper to validate the DELETE command
    get_regex DELETE "$sql_query"
    if [[ $? -eq 1 ]]; then
        table_name="${BASH_REMATCH[1]}"
        where_clause="${BASH_REMATCH[2]}"
    else
        echo "Invalid DELETE command. Ensure the format is: DELETE FROM <table> WHERE <condition>"
        return
    fi

    table_directory="$DB_DIR/$table_name"
    table_meta="$table_directory/$table_name.meta"
    table_data="$table_directory/$table_name.txt"

    # Check if the table exists
    if [ ! -f "$table_meta" ] || [ ! -f "$table_data" ]; then
        echo "Error: Table '$table_name' does not exist."
        return
    fi

    # Get the fields from the table metadata
    fields=($(grep "Fields:" "$table_meta" | cut -d' ' -f2-))

    # Extract WHERE column and value
    where_column=$(echo "$where_clause" | cut -d'=' -f1 | xargs)
    where_value=$(echo "$where_clause" | cut -d'=' -f2 | xargs | sed "s/^'\(.*\)'$/\1/" | sed 's/;$//') # Remove quotes and trailing semicolon

    where_index=$(echo "${fields[@]}" | tr ' ' '\n' | grep -n -w "$where_column" | cut -d: -f1)

    # Check if the WHERE column exists in the table
    if [[ -z "$where_index" ]]; then
        echo "Error: Column '$where_column' does not exist in table '$table_name'."
        return
    fi

    # Create a temporary file
    temp_file=$(mktemp)

    deleted=false
    while IFS= read -r line; do
        # Separate the row data into an array using space as the delimiter
        IFS=' ' read -ra row_data <<<"$line"

        # Skip the header row
        if [[ "${row_data[*]}" == "${fields[*]}" ]]; then
            echo "$line" >>"$temp_file"
            continue
        fi

        # Check if the row matches the WHERE condition
        echo "Checking WHERE clause: ${row_data[$((where_index - 1))]} == $where_value" # Debug
        if [[ "${row_data[$((where_index - 1))]}" == "$where_value" ]]; then
            deleted=true
            continue
        fi

        # Write the unchanged row to the temp file
        echo "${row_data[*]}" >>"$temp_file"
    done <"$table_data"

    if $deleted; then
        mv "$temp_file" "$table_data"
        echo "Row deleted successfully."
    else
        rm "$temp_file"
        echo "No rows matched the WHERE clause."
    fi
}

#MAIN
function main() {

    PS3="Choose an Option: "
    while true; do
        echo "------------"
        echo "DBMS Menu:"
        echo "------------"
        echo ""

        select choice in "Create Database" "List Databases" "Connect to Database" "Drop Database" "Exit"; do
            case $choice in
            "Create Database")
                clear
                create_database
                ;;
            "List Databases")
                clear
                list_databases
                ;;
            "Connect to Database")
                clear
                list_databases
                connect_database
                ;;
            "Drop Database")
                clear
                drop_database
                ;;
            "Exit") exit 0 ;;
            *) echo "Invalid choice. Please choose again." ;;
            esac
            break
        done

    done
}

# RUN
main
