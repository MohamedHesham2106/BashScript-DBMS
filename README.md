# Bash-Based Relational DBMS 

This project is a lightweight **Relational Database Management System (DBMS)** implemented in **Bash**. It allows you to create, manage, and interact with databases, tables, and records using SQL-like commands, all from the command line.

## Features ✨
- **Database Operations**:  
  - Create, list, connect to, and delete databases.
- **Table Operations**:  
  - Create tables with column definitions and primary keys.  
  - Insert, select, update, and delete data with SQL-like syntax.  
- **Supported Data Types**:  
  - `INTEGER`, `FLOAT`, `TEXT`, `DATE` (in `YYYY-MM-DD` format).  
- **Command Validation**:  
  - Input commands are validated to ensure correctness before execution.  

## Getting Started 🚀

### Prerequisites
- A Unix-based system with Bash (e.g., Linux, macOS).
- Basic understanding of SQL commands.

### Installation
Clone this repository to your local machine:
```bash
git clone https://github.com/MohamedHesham2106/BashScript-DBMS.git
```

Make the script executable:
```bash
chmod +x dbms.sh
```

Run the script:
```bash
./dbms.sh
```

### Directory Structure
- **Databases**: All databases are stored in a folder structure under `$HOME/DBMS/Databases`.  
- **Tables**: Each table is a directory containing metadata and data files.  
  - `tablename.meta`: Table schema (fields, data types, primary key).  
  - `tablename.txt`: Table data, stored in rows.

## Usage 🛠️
After starting the script, you’ll see a menu with the following options:

1. **Create Database**  
   Enter a database name to create a new database.

2. **List Databases**  
   View all existing databases.

3. **Connect to Database**  
   Select a database to perform operations on its tables.

4. **Drop Database**  
   Permanently delete a database and all its contents.

5. **Exit**  
   Exit the program.

---

### Inside a Database: Table Menu 📋
When connected to a database, the following commands are available:

#### Table Commands:
- **Create Table**
  ```sql
  CREATE TABLE table_name (column1:datatype, column2:datatype PRIMARY KEY, ...);
  ```
  Example:
  ```sql
  CREATE TABLE users (id:INTEGER PRIMARY KEY, name:TEXT, salary:FLOAT, dob:DATE);
  ```

- **Insert Data**
  ```sql
  INSERT INTO table_name (column1, column2, ...) VALUES (value1, value2, ...);
  ```
  Example:
  ```sql
  INSERT INTO users (id, name, salary, dob) VALUES (1, 'Alice', 50000.00, '1990-01-01');
  ```

- **Select Data**
  - Select all columns:
    ```sql
    SELECT * FROM table_name;
    ```
  - Select specific columns:
    ```sql
    SELECT column1, column2 FROM table_name;
    ```

- **Update Data**
  ```sql
  UPDATE table_name SET column1=value1, column2=value2 WHERE column3=value3;
  ```
  Example:
  ```sql
  UPDATE users SET salary=55000 WHERE id=1;
  ```

- **Delete Data**
  ```sql
  DELETE FROM table_name WHERE column=value;
  ```
  Example:
  ```sql
  DELETE FROM users WHERE id=1;
  ```

#### Exit the Table Menu:
Type `EXIT` to return to the main menu.

---

## Error Handling 🛡️
- Input commands are validated using **regex** to prevent malformed queries.
- Common errors are handled gracefully, with descriptive error messages:
  - Invalid commands.
  - Non-existent databases or tables.
  - Violations of primary key constraints.
  - Missing columns or mismatched data types.

## Research Areas 🛑
- **IFS with read -ra <<<**: The read command in Bash, particularly the use of the -ra option, allows reading input into an array. The <<< operator is used to provide input to read as a string, and the IFS (Internal Field Separator) defines how the input is split into array elements.<br/>This method was necessary to handle space-separated values and split them into an array for further processing.

- **Regular Expressions (REGEX)**: Regular expressions are a powerful tool for pattern matching in strings. Bash supports basic regex matching through the `[[ ]]` test construct, and advanced regex features can be accessed with external tools like `grep` or `sed`

- **BASH_REMATCH**: The `BASH_REMATCH` array is populated with the results of regex matches in Bash. It holds the entire matched string in `${BASH_REMATCH[0]}` and individual captured groups in subsequent indices.<br/>This array was used to capture and process specific portions of strings matched by regular expressions.

- **tr Command**: `tr` was useful for transforming data, such as converting characters to uppercase or removing unwanted characters.

- **column Command**: This command was essential for displaying data in a readable and organized format, especially when dealing with tabular data.

## Future Enhancements 🌟
- Add support for advanced SQL features (e.g., `ALTER TABLE`, `JOIN`).
- Implement transactions and rollback functionality.
- Support for additional data types like `VARCHAR(n)`.