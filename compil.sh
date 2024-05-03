    psql -U cobol -d student -f ./Database/create_student_table.sql
    psql -U cobol -d student -f ./Database/create_course_table.sql
    psql -U cobol -d student -f ./Database/create_grade_table.sql

    export COB_LDFLAGS=-Wl,--no-as-needed
    export COBCPY=./Copybook

    ocesql prog.cbl prog.cob
    cobc -locesql -x -o run prog.cob 

psql -d student -U cobol -c "\d+ STUDENT" -c "SELECT * FROM STUDENT;" -c "\d+ COURSE" -c "SELECT * FROM COURSE;" -c "DELETE FROM grade WHERE id = 43;" -c "\d+ GRADE" -c "SELECT * FROM GRADE;" > tables_description_and_content.txt

    ./run