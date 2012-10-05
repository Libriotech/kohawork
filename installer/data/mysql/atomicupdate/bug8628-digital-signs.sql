-- SQL related to Bug 8628 - Add digital signs to the OPAC

-- DEBUG TODO Delete before submitting patch
DELETE FROM systempreferences WHERE variable = 'OPACDigitalSigns';
DELETE FROM systempreferences WHERE variable = 'OPACDigitalSignsRecordTemplate';
DELETE FROM permissions WHERE code = 'edit_digital_signs';
DELETE FROM saved_sql;

INSERT INTO systempreferences (variable,value,explanation,type) VALUES ('OPACDigitalSigns',1,'Turn digital signs in the OPAC on or off.','YesNo');
INSERT INTO systempreferences (variable,value,explanation,type) VALUES ('OPACDigitalSignsRecordTemplate',"<p>Title: [% record.field('245').subfield('a') %][% IF record.field('245').subfield('b') %] : [% record.field('245').subfield('b') %][% END %]</p>

[% IF record.field('260').subfield('b') %]
<p>Publisher: [% record.field('260').subfield('b') %]</p>
[% END %]

[%- IF record.field('700') %]
  <p>Authors:</p>
  <ul>
  [%- FOREACH f IN record.field('700') %]
    <li>[% f.subfield('a') %]</li>
  [%- END %]
  </ul>
[%- END %]",'Template for formatting MARC records for display in digital signs.','Textarea');

INSERT INTO permissions (module_bit, code, description) VALUES (13, 'edit_digital_signs', 'Create and edit digital signs for the OPAC');

-- TODO Add these tables to kohasctructure.sql
DROP TABLE IF EXISTS sign_streams;
CREATE TABLE sign_streams (
  sign_stream_id int(11) NOT NULL auto_increment,    -- primary key, used to identify streams
  saved_sql_id int(11) NOT NULL,              -- foreign key from the saved_sql table
  name varchar(32),                           -- name/title of the sign
  PRIMARY KEY (sign_stream_id),
  CONSTRAINT sign_streams_ibfk_1 FOREIGN KEY (saved_sql_id) REFERENCES saved_sql (id) ON DELETE CASCADE
);
DROP TABLE IF EXISTS signs;
CREATE TABLE signs (
  sign_id int(11) NOT NULL auto_increment,    -- primary key, used to identify signs
  name varchar(32),                           -- name/title of the deck
  branchcode varchar(10) NOT NULL default '', -- foreign key from the branches table
  webapp int(1) NOT NULL default 0,           -- display as web app or normal page
  PRIMARY KEY (sign_id),
  CONSTRAINT signs_ibfk_1 FOREIGN KEY (branchcode) REFERENCES branches (branchcode) -- ON DELETE CASCADE
);
DROP TABLE IF EXISTS signs_to_streams;
CREATE TABLE signs_to_streams (
  sign_stream_id int(11) NOT NULL, -- foreign key from the decks sign_streams table
  sign_id int(11) NOT NULL,        -- foreign key from the signs table
  PRIMARY KEY (sign_stream_id,sign_id),
  CONSTRAINT signs_to_streams_ibfk_1 FOREIGN KEY (sign_stream_id) REFERENCES sign_streams (sign_stream_id) ON DELETE CASCADE,
  CONSTRAINT signs_to_streams_ibfk_2 FOREIGN KEY (sign_id) REFERENCES signs (sign_id) ON DELETE CASCADE
);


-- Sample data for testing
-- TODO Delete before submitting patch
-- mysqldump -u koha -p koha --complete-insert --skip-quote-names --tables <tablename>

INSERT INTO saved_sql
( id, borrowernumber,  date_created,          last_modified,         savedsql,                                                                                               last_run,  report_name,       type,  notes, cache_expiry, public ) VALUES
( 1,  51,             '2012-08-22 12:55:33', '2012-08-22 12:55:33', 'SELECT biblionumber, title FROM biblio ORDER BY biblionumber DESC LIMIT 20',                            NULL,     'Newest titles',    1,     NULL,  300,          1 ),
( 2,  51,             '2012-08-22 12:55:33', '2012-08-22 12:55:33', 'SELECT biblionumber, title FROM biblio WHERE copyrightdate = 2012 ORDER BY biblionumber DESC LIMIT 20', NULL,     'Titles from 2012', 1,     NULL,  300,          1 ),
( 3,  51,             '2012-08-22 12:55:33', '2012-08-22 12:55:33', 'SELECT biblionumber, title FROM biblio ORDER BY RAND() DESC LIMIT 20',                                  NULL,     'Random titles',    1,     NULL,  300,          1 ),
( 4,  51,             '2012-09-04 12:55:33', '2012-09-04 12:55:33', 'SELECT biblionumber, title FROM biblio WHERE title LIKE "%Perl%" OR title LIKE "%PHP%" ORDER BY RAND() DESC', NULL, 'Tech books',     1, NULL, 300,          1 );

INSERT INTO signs ( sign_id, branchcode, name, webapp ) VALUES ( 1, 'CPL', 'Signs for the main library', 1 );

INSERT INTO sign_streams ( sign_stream_id, saved_sql_id, name ) VALUES ( 1, 1, 'Newest titles' );
INSERT INTO sign_streams ( sign_stream_id, saved_sql_id, name ) VALUES ( 2, 2, 'Titles from 2012' );
INSERT INTO sign_streams ( sign_stream_id, saved_sql_id, name ) VALUES ( 3, 3, 'Random titles' );
INSERT INTO sign_streams ( sign_stream_id, saved_sql_id, name ) VALUES ( 4, 4, 'Tech books' );

INSERT INTO signs_to_streams (sign_id, sign_stream_id) VALUES (1,1),(1,2),(1,3),(1,4);
