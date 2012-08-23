-- SQL related to Bug 8628 - Add digital signs to the OPAC

-- DEBUG TODO Delete before submitting patch
DELETE FROM systempreferences WHERE variable = 'OPACDigitalSigns';
DELETE FROM permissions WHERE code = 'edit_digital_signs';
TRUNCATE saved_sql;

INSERT INTO systempreferences (variable,value,explanation,type) VALUES ('OPACDigitalSigns',0,'Turn digital signs in the OPAC on or off.','YesNo');

INSERT INTO permissions (module_bit, code, description) VALUES (13, 'edit_digital_signs', 'Create and edit digital signs for the OPAC');

-- TODO Add these tables to kohasctructure.sql
DROP TABLE IF EXISTS signs;
CREATE TABLE signs (
  sign_id int(11) NOT NULL auto_increment,    -- primary key, used to identify signs
  saved_sql_id int(11) NOT NULL,              -- foreign key from the saved_sql table
  name varchar(32),                           -- name/title of the sign
  PRIMARY KEY (sign_id),
  CONSTRAINT signs_ibfk_1 FOREIGN KEY (saved_sql_id) REFERENCES saved_sql (id) -- TODO on delete cascade?
);
DROP TABLE IF EXISTS decks;
CREATE TABLE decks (
  deck_id int(11) NOT NULL auto_increment,    -- primary key, used to identify decks
  name varchar(32),                           -- name/title of the deck
  branchcode varchar(10) NOT NULL default '', -- foreign key from the branches table
  PRIMARY KEY (deck_id),
  CONSTRAINT dekcs_ibfk_1 FOREIGN KEY (branchcode) REFERENCES branches (branchcode)
);

-- TODO Add signstack table
--   branchcode varchar(10) NOT NULL default '', -- foreign key from the branches table

-- Sample data for testing
-- TODO Delete before submitting patch

INSERT INTO saved_sql
( id, borrowernumber,  date_created,          last_modified,         savedsql,                                                           last_run,  report_name,    type,  notes, cache_expiry, public ) VALUES
( 1,  51,             '2012-08-22 12:55:33', '2012-08-22 12:55:33', 'SELECT COUNT(*) FROM biblio',                                       NULL,     'test for sign', 1,     NULL,  300,          1 ),
( 2,  51,             '2012-08-22 13:14:54', '2012-08-22 13:14:54', 'SELECT biblio.biblionumber,biblio.title FROM biblioitems LIMIT 10', NULL,     'custom report 02', 1,     NULL,  300,          0 ),
( 3,  51,             '2012-08-22 13:14:54', '2012-08-22 13:14:54', 'SELECT biblio.biblionumber,biblio.title FROM biblioitems LIMIT 10', NULL,     'custom report 03', 1,     NULL,  300,          0 ),
( 4,  51,             '2012-08-22 13:14:54', '2012-08-22 13:14:54', 'SELECT biblio.biblionumber,biblio.title FROM biblioitems LIMIT 10', NULL,     'custom report 04', 1,     NULL,  300,          0 ),
( 5,  51,             '2012-08-22 13:14:54', '2012-08-22 13:14:54', 'SELECT biblio.biblionumber,biblio.title FROM biblioitems LIMIT 10', NULL,     'custom report 05', 1,     NULL,  300,          0 ),
( 6,  51,             '2012-08-22 13:14:54', '2012-08-22 13:14:54', 'SELECT biblio.biblionumber,biblio.title FROM biblioitems LIMIT 10', NULL,     'custom report 06', 1,     NULL,  300,          0 ),
( 7,  51,             '2012-08-22 13:14:54', '2012-08-22 13:14:54', 'SELECT biblio.biblionumber,biblio.title FROM biblioitems LIMIT 10', NULL,     'custom report 07', 1,     NULL,  300,          0 ),
( 8,  51,             '2012-08-22 13:14:54', '2012-08-22 13:14:54', 'SELECT biblio.biblionumber,biblio.title FROM biblioitems LIMIT 10', NULL,     'custom report 08', 1,     NULL,  300,          0 ),
( 9,  51,             '2012-08-22 13:14:54', '2012-08-22 13:14:54', 'SELECT biblio.biblionumber,biblio.title FROM biblioitems LIMIT 10', NULL,     'custom report 09', 1,     NULL,  300,          0 ),
( 10,  51,             '2012-08-22 13:14:54', '2012-08-22 13:14:54', 'SELECT biblio.biblionumber,biblio.title FROM biblioitems LIMIT 10', NULL,     'custom report 10', 1,     NULL,  300,          0 ),
( 11,  51,             '2012-08-22 13:14:54', '2012-08-22 13:14:54', 'SELECT biblio.biblionumber,biblio.title FROM biblioitems LIMIT 10', NULL,     'custom report 11', 1,     NULL,  300,          0 ),
( 12,  51,             '2012-08-22 13:14:54', '2012-08-22 13:14:54', 'SELECT biblio.biblionumber,biblio.title FROM biblioitems LIMIT 10', NULL,     'custom report 12', 1,     NULL,  300,          0 ),
( 13,  51,             '2012-08-22 13:14:54', '2012-08-22 13:14:54', 'SELECT biblio.biblionumber,biblio.title FROM biblioitems LIMIT 10', NULL,     'custom report 13', 1,     NULL,  300,          0 );

INSERT INTO decks ( deck_id, branchcode, name ) VALUES ( 1, 'CPL', 'deck 01' );
INSERT INTO decks ( deck_id, branchcode, name ) VALUES ( 2, 'CPL', 'deck 02' );
INSERT INTO decks ( deck_id, branchcode, name ) VALUES ( 3, 'CPL', 'deck 03' );
INSERT INTO decks ( deck_id, branchcode, name ) VALUES ( 4, 'CPL', 'deck 04' );
INSERT INTO decks ( deck_id, branchcode, name ) VALUES ( 5, 'CPL', 'deck 05' );
INSERT INTO decks ( deck_id, branchcode, name ) VALUES ( 6, 'CPL', 'deck 06' );
INSERT INTO decks ( deck_id, branchcode, name ) VALUES ( 7, 'CPL', 'deck 07' );
INSERT INTO decks ( deck_id, branchcode, name ) VALUES ( 8, 'CPL', 'deck 08' );
INSERT INTO decks ( deck_id, branchcode, name ) VALUES ( 9, 'CPL', 'deck 09' );
INSERT INTO decks ( deck_id, branchcode, name ) VALUES ( 10, 'CPL', 'deck 10' );
INSERT INTO decks ( deck_id, branchcode, name ) VALUES ( 11, 'CPL', 'deck 11' );
INSERT INTO decks ( deck_id, branchcode, name ) VALUES ( 12, 'CPL', 'deck 12' );
INSERT INTO decks ( deck_id, branchcode, name ) VALUES ( 13, 'CPL', 'deck 13' );

INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 1, 1, 'sign with report 01' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 2, 1, 'sign with report 02' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 3, 1, 'sign with report 03' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 4, 1, 'sign with report 04' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 5, 1, 'sign with report 05' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 6, 1, 'sign with report 06' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 7, 1, 'sign with report 07' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 8, 1, 'sign with report 08' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 9, 1, 'sign with report 09' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 10, 1, 'sign with report 10' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 11, 1, 'sign with report 11' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 12, 1, 'sign with report 12' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 13, 1, 'sign with report 13' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 14, 1, 'sign with report 14' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 15, 1, 'sign with report 15' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 16, 1, 'sign with report 16' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 17, 1, 'sign with report 17' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 18, 1, 'sign with report 18' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 19, 1, 'sign with report 19' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 20, 1, 'sign with report 20' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 21, 1, 'sign with report 21' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 22, 1, 'sign with report 22' );
INSERT INTO signs ( sign_id, saved_sql_id, name ) VALUES ( 23, 1, 'sign with report 23' );
