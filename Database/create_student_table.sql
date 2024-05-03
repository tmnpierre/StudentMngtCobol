DROP TABLE IF EXISTS STUDENT;

CREATE TABLE STUDENT
(
    ID SERIAL PRIMARY KEY,
    LASTNAME CHAR(35) NOT NULL DEFAULT 'DUPOND',
    FIRSTNAME CHAR(35) NOT NULL DEFAULT 'MonsieurMadame',
    AGE SMALLINT NOT NULL DEFAULT 99
);