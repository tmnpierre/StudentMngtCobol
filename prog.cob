       IDENTIFICATION DIVISION.
       PROGRAM-ID. prog.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT F-INPUT
               ASSIGN TO 'input.dat'
               ACCESS MODE IS SEQUENTIAL
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS F-INPUT-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  F-INPUT
           RECORD CONTAINS 2 TO 1000 CHARACTERS 
           RECORDING MODE IS V.

       01  REC-F-INPUT-2         PIC X(02).

       01  REC-STUDENT.
           03 R-S-KEY            PIC 9(02).       
           03 R-S-LASTNAME       PIC X(07).       
           03 R-S-FIRSTNAME      PIC X(06).       
           03 R-S-AGE            PIC 9(02).

       01  REC-COURSE.
           03 R-C-KEY            PIC 9(02).       
           03 R-C-LABEL          PIC X(21).       
           03 R-C-COEF           PIC X(03).       
           03 R-C-GRADE          PIC X(05).

       WORKING-STORAGE SECTION.
       01  F-INPUT-STATUS      PIC X(02) VALUE SPACE.
           88 F-INPUT-STATUS-OK    VALUE '00'.        
           88 F-INPUT-STATUS-EOF   VALUE '10'.

OCESQL*EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01  DBNAME                  PIC  X(30) VALUE 'student'.
       01  USERNAME                PIC  X(30) VALUE 'cobol'.
       01  PASSWD                  PIC  X(10) VALUE SPACE.

       01  SQL-STUDENT.
           05  SQL-S-LASTNAME           PIC X(07).
           05  SQL-S-FIRSTNAME          PIC X(06).
           05  SQL-S-AGE                PIC 9(02).
       
       01  SQL-COURSE.
           05  SQL-C-LABEL              PIC X(35).
           05  SQL-C-COEF               PIC 9V9.

OCESQL*EXEC SQL END DECLARE SECTION END-EXEC.

OCESQL*EXEC SQL INCLUDE SQLCA END-EXEC.
OCESQL     copy "sqlca.cbl".

OCESQL*
OCESQL 01  SQ0001.
OCESQL     02  FILLER PIC X(014) VALUE "DISCONNECT ALL".
OCESQL     02  FILLER PIC X(1) VALUE X"00".
OCESQL*
OCESQL 01  SQ0002.
OCESQL     02  FILLER PIC X(068) VALUE "INSERT INTO STUDENT (LASTNAME,"
OCESQL  &  " FIRSTNAME, AGE) VALUES ( $1, $2, $3 )".
OCESQL     02  FILLER PIC X(1) VALUE X"00".
OCESQL*
OCESQL 01  SQ0003.
OCESQL     02  FILLER PIC X(105) VALUE "INSERT INTO COURSE (LABEL, COE"
OCESQL  &  "F) SELECT $1, $2 WHERE NOT EXISTS ( SELECT 1 FROM COURSE W"
OCESQL  &  "HERE LABEL = $3 )".
OCESQL     02  FILLER PIC X(1) VALUE X"00".
OCESQL*
       PROCEDURE DIVISION.
       1000-MAIN-START.
OCESQL*    EXEC SQL
OCESQL*        CONNECT :USERNAME IDENTIFIED BY :PASSWD USING :DBNAME 
OCESQL*    END-EXEC.
OCESQL     CALL "OCESQLConnect" USING
OCESQL          BY REFERENCE SQLCA
OCESQL          BY REFERENCE USERNAME
OCESQL          BY VALUE 30
OCESQL          BY REFERENCE PASSWD
OCESQL          BY VALUE 10
OCESQL          BY REFERENCE DBNAME
OCESQL          BY VALUE 30
OCESQL     END-CALL.

           IF  SQLCODE NOT = ZERO 
               PERFORM 1001-ERROR-RTN-START
                   THRU 1001-ERROR-RTN-END
           END-IF.
           
           PERFORM 7001-FILE-READ-START
               THRU 7001-FILE-READ-END.

       1000-MAIN-END.
OCESQL*    EXEC SQL COMMIT WORK END-EXEC.
OCESQL     CALL "OCESQLStartSQL"
OCESQL     END-CALL
OCESQL     CALL "OCESQLExec" USING
OCESQL          BY REFERENCE SQLCA
OCESQL          BY REFERENCE "COMMIT" & x"00"
OCESQL     END-CALL
OCESQL     CALL "OCESQLEndSQL"
OCESQL     END-CALL.
OCESQL*    EXEC SQL DISCONNECT ALL END-EXEC.  
OCESQL     CALL "OCESQLDisconnect" USING
OCESQL          BY REFERENCE SQLCA
OCESQL     END-CALL.
           STOP RUN. 
      ******************************************************************
       1001-ERROR-RTN-START.
           DISPLAY "*** SQL ERROR ***".
           DISPLAY "SQLCODE: " SQLCODE SPACE.
           EVALUATE SQLCODE
              WHEN  +100
                 DISPLAY "Record not found"
              WHEN  -01
                 DISPLAY "Connection failed"
              WHEN  -20
                 DISPLAY "Internal error"
              WHEN  -30
                 DISPLAY "PostgreSQL error"
                 DISPLAY "ERRCODE:" SPACE SQLSTATE
                 DISPLAY SQLERRMC
              *> TO RESTART TRANSACTION, DO ROLLBACK.
OCESQL*          EXEC SQL
OCESQL*              ROLLBACK
OCESQL*          END-EXEC
OCESQL     CALL "OCESQLStartSQL"
OCESQL     END-CALL
OCESQL     CALL "OCESQLExec" USING
OCESQL          BY REFERENCE SQLCA
OCESQL          BY REFERENCE "ROLLBACK" & x"00"
OCESQL     END-CALL
OCESQL     CALL "OCESQLEndSQL"
OCESQL     END-CALL
              WHEN  OTHER
                 DISPLAY "Undefined error"
                 DISPLAY "ERRCODE:" SPACE SQLSTATE
                 DISPLAY SQLERRMC
           END-EVALUATE.
       1001-ERROR-RTN-END.
           STOP RUN. 
      ******************************************************************
       7001-FILE-READ-START.
           OPEN INPUT F-INPUT.
           IF NOT F-INPUT-STATUS-OK
               DISPLAY 'ABORT POPULATING TABLE'
               GO TO 7001-FILE-READ-END
           END-IF.
           
           PERFORM UNTIL F-INPUT-STATUS-EOF
               READ F-INPUT
               EVALUATE REC-F-INPUT-2
                   WHEN '01'
                       PERFORM 7101-FILE-HANDLE-STUDENT-START
                           THRU 7101-FILE-HANDLE-STUDENT-END
                   WHEN '02'
                       PERFORM 7201-FILE-HANDLE-COURSE-START
                           THRU 7201-FILE-HANDLE-COURSE-END
                   WHEN OTHER
                       CONTINUE
               END-EVALUATE
           END-PERFORM.
       7001-FILE-READ-END.
           CLOSE F-INPUT.
      ******************************************************************
       7101-FILE-HANDLE-STUDENT-START.
           MOVE R-S-LASTNAME TO SQL-S-LASTNAME.
           MOVE R-S-FIRSTNAME TO SQL-S-FIRSTNAME.
           MOVE R-S-AGE TO SQL-S-AGE.

OCESQL*    EXEC SQL
OCESQL*        INSERT INTO STUDENT (LASTNAME, FIRSTNAME, AGE) 
OCESQL*        VALUES (
OCESQL*            :SQL-S-LASTNAME, 
OCESQL*            :SQL-S-FIRSTNAME,
OCESQL*            :SQL-S-AGE
OCESQL*        )
OCESQL*    END-EXEC.
OCESQL     CALL "OCESQLStartSQL"
OCESQL     END-CALL
OCESQL     CALL "OCESQLSetSQLParams" USING
OCESQL          BY VALUE 16
OCESQL          BY VALUE 7
OCESQL          BY VALUE 0
OCESQL          BY REFERENCE SQL-S-LASTNAME
OCESQL     END-CALL
OCESQL     CALL "OCESQLSetSQLParams" USING
OCESQL          BY VALUE 16
OCESQL          BY VALUE 6
OCESQL          BY VALUE 0
OCESQL          BY REFERENCE SQL-S-FIRSTNAME
OCESQL     END-CALL
OCESQL     CALL "OCESQLSetSQLParams" USING
OCESQL          BY VALUE 1
OCESQL          BY VALUE 2
OCESQL          BY VALUE 0
OCESQL          BY REFERENCE SQL-S-AGE
OCESQL     END-CALL
OCESQL     CALL "OCESQLExecParams" USING
OCESQL          BY REFERENCE SQLCA
OCESQL          BY REFERENCE SQ0002
OCESQL          BY VALUE 3
OCESQL     END-CALL
OCESQL     CALL "OCESQLEndSQL"
OCESQL     END-CALL.
       7101-FILE-HANDLE-STUDENT-END.
      ******************************************************************
       7201-FILE-HANDLE-COURSE-START.
           MOVE R-C-LABEL TO SQL-C-LABEL.
           MOVE R-C-COEF TO SQL-C-COEF.

OCESQL*    EXEC SQL
OCESQL*        INSERT INTO COURSE (LABEL, COEF)
OCESQL*        SELECT :SQL-C-LABEL, :SQL-C-COEF
OCESQL*        WHERE NOT EXISTS (
OCESQL*            SELECT 1 FROM COURSE WHERE LABEL = :SQL-C-LABEL
OCESQL*        )
OCESQL*    END-EXEC.
OCESQL     CALL "OCESQLStartSQL"
OCESQL     END-CALL
OCESQL     CALL "OCESQLSetSQLParams" USING
OCESQL          BY VALUE 16
OCESQL          BY VALUE 35
OCESQL          BY VALUE 0
OCESQL          BY REFERENCE SQL-C-LABEL
OCESQL     END-CALL
OCESQL     CALL "OCESQLSetSQLParams" USING
OCESQL          BY VALUE 1
OCESQL          BY VALUE 2
OCESQL          BY VALUE -1
OCESQL          BY REFERENCE SQL-C-COEF
OCESQL     END-CALL
OCESQL     CALL "OCESQLSetSQLParams" USING
OCESQL          BY VALUE 16
OCESQL          BY VALUE 35
OCESQL          BY VALUE 0
OCESQL          BY REFERENCE SQL-C-LABEL
OCESQL     END-CALL
OCESQL     CALL "OCESQLExecParams" USING
OCESQL          BY REFERENCE SQLCA
OCESQL          BY REFERENCE SQ0003
OCESQL          BY VALUE 3
OCESQL     END-CALL
OCESQL     CALL "OCESQLEndSQL"
OCESQL     END-CALL.
       7201-FILE-HANDLE-COURSE-END.
      ******************************************************************
      ******************************************************************
      ******************************************************************
