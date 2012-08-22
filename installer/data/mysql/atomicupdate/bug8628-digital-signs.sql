-- SQL related to Bug 8628 - Add digital signs to the OPAC

-- DEBUG TODO Delete before submitting patch
DELETE FROM systempreferences WHERE variable = 'OPACDigitalSigns';
DELETE FROM permissions WHERE code = 'edit_digital_signs';
TRUNCATE saved_sql;

INSERT INTO systempreferences (variable,value,explanation,type) VALUES ('OPACDigitalSigns',0,'Turn digital signs in the OPAC on or off.','YesNo');

INSERT INTO permissions (module_bit, code, description) VALUES (13, 'edit_digital_signs', 'Create and edit digital signs for the OPAC');

-- TODO Add this table to kohasctructure.sql
DROP TABLE IF EXISTS signs;
CREATE TABLE signs (
  sign_id int(11) NOT NULL auto_increment,    -- primary key, used to identify signs
  saved_sql_id int(11) NOT NULL,              -- foreign key from the saved_sql table
  name varchar(32),                           -- name/title of the sign
  PRIMARY KEY (sign_id),
  CONSTRAINT signs_ibfk_1 FOREIGN KEY (saved_sql_id) REFERENCES saved_sql (id) -- TODO on delete cascade?
);

-- TODO Add signstack table
--   branchcode varchar(10) NOT NULL default '', -- foreign key from the branches table

-- Sample data for testing
-- TODO Delete before submitting patch

INSERT INTO saved_sql
( id, borrowernumber,  date_created,          last_modified,         savedsql,                                                           last_run,  report_name,    type,  notes, cache_expiry, public ) VALUES
( 1,  51,             '2012-08-22 12:55:33', '2012-08-22 12:55:33', 'SELECT COUNT(*) FROM biblio',                                       NULL,     'test for sign', 1,     NULL,  300,          1 ),
( 2,  51,             '2012-08-22 13:14:54', '2012-08-22 13:14:54', 'SELECT biblio.biblionumber,biblio.title FROM biblioitems LIMIT 10', NULL,     'custom report', 1,     NULL,  300,          0 );

INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 1, 1, 'sign with report' );
