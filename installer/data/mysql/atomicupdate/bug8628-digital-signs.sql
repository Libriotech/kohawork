-- SQL related to Bug 8628 - Add digital signs to the OPAC

INSERT INTO systempreferences (variable,value,explanation,type) VALUES ('OPACDigitalSigns',0,'Turn digital signs in the OPAC on or off.','YesNo');

INSERT INTO permissions (module_bit, code, description) VALUES (13, 'edit_digital_signs', 'Create and edit digital signs for the OPAC');
