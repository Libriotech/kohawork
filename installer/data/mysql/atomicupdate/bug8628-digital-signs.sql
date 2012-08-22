-- SQL related to Bug 8628 - Add digital signs to the OPAC

-- DEBUG
-- TODO Delete before submitting patch
DELETE FROM systempreferences WHERE variable = 'OPACDigitalSigns';
DELETE FROM permissions WHERE code = 'edit_digital_signs';

INSERT INTO systempreferences (variable,value,explanation,type) VALUES ('OPACDigitalSigns',0,'Turn digital signs in the OPAC on or off.','YesNo');

INSERT INTO permissions (module_bit, code, description) VALUES (13, 'edit_digital_signs', 'Create and edit digital signs for the OPAC');

DROP TABLE IF EXISTS signs;
CREATE TABLE signs (
  sign_id int(11) NOT NULL auto_increment, -- primary key, used to identify signs
  branchcode varchar(10) NOT NULL default '', -- foreign key from the branches table
  name varchar(32), -- name/title of the sign
  PRIMARY KEY (sign_id),
  CONSTRAINT signs_ibfk_1 FOREIGN KEY (branchcode) REFERENCES branches (branchcode)
);

-- Sample data for testing
-- TODO Delete before submitting patch
