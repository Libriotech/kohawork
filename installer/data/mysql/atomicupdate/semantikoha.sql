-- TODO Add these to sysprefs.sql
INSERT INTO systempreferences SET variable = 'OPACDetailViewLinkedData', value = 0, options = NULL, explanation = "Show or hide Linked Data in the OPAC detail view.", type = 'YesNo';

-- TODO Add tables to kohastructure.sql
CREATE TABLE ld_main_template (
    ld_main_template_id INT(12) NOT NULL auto_increment, -- primary key
    type_uri VARCHAR(255) NOT NULL, -- URI that the template should be associated with
    name VARCHAR(255) NOT NULL, -- mnemonic name for the template
    main_template TEXT NOT NULL, -- the actual template
    PRIMARY KEY  (ld_main_template_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO ld_main_template SET type_uri = 'https://id.kb.se/vocab/SoundRecording', name = 'Sound recording', main_template = '<h2>Sound recording</h2>
{{series}}';

INSERT INTO ld_main_template SET type_uri = 'http://bibframe.org/vocab/Serial', name = 'Serial', main_template = '<h2>Series</h2>
{{series_members}}';

CREATE TABLE ld_queries_templates (
    ld_queries_templates_id INT(12) NOT NULL auto_increment, -- primary key
    slug CHAR(32) NOT NULL, -- short textual name for the query/template
    ld_main_template_id INT(12) NOT NULL, -- foreign key to link to ld_main_template.ld_main_template_id
    name VARCHAR(255) NOT NULL, -- mnemonic name
    query TEXT NOT NULL, -- the actual query
    template TEXT NOT NULL, -- the actual template
    PRIMARY KEY  (ld_queries_templates_id),
    UNIQUE KEY slug (slug),
    CONSTRAINT queries_templates_bnfk
        FOREIGN KEY (ld_main_template_id)
        REFERENCES ld_main_template (ld_main_template_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
