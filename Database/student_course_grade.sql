-- Drop existing tables if they exist
DROP TABLE IF EXISTS grade;
DROP TABLE IF EXISTS course;
DROP TABLE IF EXISTS student;

-- Create the STUDENT table
CREATE TABLE STUDENT
(
    ID SERIAL PRIMARY KEY,
    LASTNAME CHAR(35) NOT NULL DEFAULT 'DUPOND',
    FIRSTNAME CHAR(35) NOT NULL DEFAULT 'MonsieurMadame',
    AGE SMALLINT NOT NULL DEFAULT 99,
    TOTAL_GRADE NUMERIC(5, 2) -- New field for storing the general average grade
);

-- Create the COURSE table
CREATE TABLE COURSE
(
    ID SERIAL PRIMARY KEY,
    LABEL CHAR(35) NOT NULL UNIQUE DEFAULT 'Manquant',
    COEF NUMERIC(3, 1) NOT NULL DEFAULT 1,
    AVERAGE_GRADE NUMERIC(5, 2) -- New field for storing the course average grade
);

-- Create the GRADE table
CREATE TABLE GRADE
(
    ID SERIAL PRIMARY KEY,
    STUDENT_ID INTEGER NOT NULL,
    COURSE_ID INTEGER NOT NULL,
    GRADE NUMERIC(5, 2) NOT NULL,
    FOREIGN KEY (STUDENT_ID) REFERENCES STUDENT(ID),
    FOREIGN KEY (COURSE_ID) REFERENCES COURSE(ID)
);

-- Indexes
CREATE INDEX idx_grade_student ON GRADE(STUDENT_ID);
CREATE INDEX idx_grade_course ON GRADE(COURSE_ID);

-- Function to update the student's total average
CREATE OR REPLACE FUNCTION update_student_total_grade() RETURNS TRIGGER AS $$
BEGIN
    UPDATE STUDENT
    SET TOTAL_GRADE = (
        SELECT COALESCE(AVG(GRADE), 0) FROM GRADE WHERE STUDENT_ID = NEW.STUDENT_ID
    )
    WHERE ID = NEW.STUDENT_ID;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update the student's total grade when a new grade is added
CREATE TRIGGER trg_update_student_total
AFTER INSERT OR UPDATE ON GRADE
FOR EACH ROW EXECUTE FUNCTION update_student_total_grade();

-- Function to update the course's average grade
CREATE OR REPLACE FUNCTION update_course_average_grade() RETURNS TRIGGER AS $$
BEGIN
    UPDATE COURSE
    SET AVERAGE_GRADE = (
        SELECT COALESCE(AVG(GRADE), 0) FROM GRADE WHERE COURSE_ID = NEW.COURSE_ID
    )
    WHERE ID = NEW.COURSE_ID;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update the course's average grade when a new grade is added
CREATE TRIGGER trg_update_course_average
AFTER INSERT OR UPDATE ON GRADE
FOR EACH ROW EXECUTE FUNCTION update_course_average_grade();