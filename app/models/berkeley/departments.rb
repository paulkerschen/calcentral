module Berkeley
  class Departments

    def self.get(dept_code, opts={})
      name = department_map[dept_code]
      name = shortened(name) if name && opts[:concise]
      name || dept_code
    end

    def self.shortened(name)
      name.sub(/^[OCDSP][\w\s]+ (of|for|in) /, '').sub(/ (Department|Institute|Academic Program|Programs?)$/, '')
    end

    #L4 codes from http://www.bai.berkeley.edu/BFS/BudgetGL/treeReports/UCBDTREE.HTM
    def self.department_map
      @department_map ||= {
        # Officially part of UGIS (Undergraduate and Interdisciplinary Studies).
        'AMERSTD' => 'American Studies',
        'BAHSB' =>  'Haas School of Business',
        'BMCCB' =>  'Center for Computational Biology',
        'BTCNM' =>  'Center for New Media',
        'BOOPT' =>  'School of Optometry',
        'BUGMS' =>  'Center for Global Metropolitan Studies',
        # Not an official department code.
        'CALTEACH' => 'CalTeach Program',
        'CCHEM' =>  'Department of Chemistry',
        'CEEEG' =>  'Department of Chemical and Biomolecular Engineering',
        # Officially part of HSCAN.
        'CELTIC' => 'Celtic Studies',
        'CFPPR' =>  'Goldman School of Public Policy',
        'CLLAW' =>  'School of Law',
        'CPACA' =>  'School of Public Health',
        'CRTHE' =>  'Program in Critical Theory',
        'CSDEP' =>  'Department of Social Welfare',
        'DACED' =>  'College of Environmental Design',
        'DBARC' =>  'Department of Architecture',
        'DCCRP' =>  'Department of City and Regional Planning',
        'DFLAE' =>  'Department of Landscape Architecture and Environmental Planning',
        'DJOUR' =>  'Department of Journalism',
        'EAEDU' =>  'School of Education',
        'EDDNO' =>  'College of Engineering',
        'EFBIO' =>  'Department of Bioengineering',
        'EGCEE' =>  'Department of Civil and Environmental Engineering',
        'EHEEC' =>  'Department of Electrical Engineering and Computer Sciences',
        'EIIEO' =>  'Department of Industrial Engineering and Operations Research',
        'EJMSM' =>  'Department of Materials Science and Engineering',
        'EKMEG' =>  'Department of Mechanical Engineering',
        'ELNUC' =>  'Department of Nuclear Engineering',
        'EUNEU' =>  'Helen Wills Neuroscience Institute',
        # Freshman and Sophomore Seminars cut across multiple department names but are treated as a
        # single pseudo-department to administer online course evaluations. The "department code"
        # is more or less arbitrary, and does not appear in the BFS General Ledger.
        'FSSEM' =>  'Freshman and Sophomore Seminars',
        'HARTH' =>  'History of Art Department',
        'HCPHI' =>  'Department of Philosophy',
        'HDRAM' =>  'Department of Theater, Dance and Performance Studies',
        'HENGL' =>  'Department of English',
        'HFREN' =>  'Department of French',
        'HGEAL' =>  'Department of East Asian Languages and Cultures',
        'HITAL' =>  'Department of Italian Studies',
        'HLCOM' =>  'Department of Comparative Literature',
        'HMUSC' =>  'Department of Music',
        'HNNES' =>  'Department of Near Eastern Studies',
        'HPMED' =>  'Program in Medieval Studies',
        'HRHET' =>  'Department of Rhetoric',
        'HSCAN' =>  'Department of Scandinavian',
        'HTAHN' =>  'Group in Ancient History and Mediterranean Archaeology',
        'HUFLM' =>  'Department of Film and Media',
        'HVSSA' =>  'Department of South and Southeast Asian Studies',
        'HZGER' =>  'Department of German',
        'IBIBI' =>  'Department of Integrative Biology',
        'IMMCB' =>  'Department of Molecular and Cell Biology',
        'IPPEP' =>  'Department of Physical Education',
        'IQBBB' =>  'QB3 Institute',
        # Officially part of QHUIS.
        'ISF' => 'Interdisciplinary Studies Field',
        'JYHST' =>  'Center for Science, Technology, Medicine and Society',
        'KDCJS' =>  'Center for Jewish Studies',
        # Not an official department code. Legal Studies is part of L&S but taught by Law staff.
        'LEGALST' => 'Legal Studies',
        'LPSPP' =>  'Department of Spanish and Portuguese',
        'LQAPR' =>  'Department of Art Practice',
        'LS1HU' =>  'L&S Arts and Humanities',
        'LSCLA' =>  'Department of Classics',
        'LTSLL' =>  'Department of Slavic Languages and Literatures',
        'MANRD' =>  'College of Natural Resources',
        'MBARC' =>  'Department of Agricultural and Resource Economics',
        'MCESP' =>  'Department of Environmental Science, Policy and Management',
        'MDNST' =>  'Department of Nutritional Sciences and Toxicology',
        # Officially part of QHUIS.
        'MEDIAST' => 'Media Studies',
        'MEPMB' =>  'Department of Plant and Microbial Biology',
        'MGERG' =>  'Energy and Resources Group',
        'MMIMS' =>  'School of Information',
        'OLGDD' =>  'Graduate Division',
        'OUNNI' =>  'Nanosciences and Nanoengineering Institute',
        'PAAST' =>  'Department of Astronomy',
        'PGEGE' =>  'Department of Earth and Planetary Science',
        'PHYSI' =>  'Department of Physics',
        'PMATH' =>  'Department of Mathematics',
        'PSTAT' =>  'Department of Statistics',
        'QHUIS' =>  'Office of Undergraduate and Interdisciplinary Studies',
        'QIIAS' =>  'International and Area Studies Academic Program',
        'QKCWP' =>  'College Writing Programs',
        'QLROT' =>  'Military Affairs Program',
        'SAAMS' =>  'Department of African American Studies',
        'SBETH' =>  'Department of Ethnic Studies',
        'SDDEM' =>  'Department of Demography',
        'SECON' =>  'Department of Economics',
        'SGEOG' =>  'Department of Geography',
        'SHIST' =>  'Department of History',
        'SISOC' =>  'Department of Sociology',
        'SLING' =>  'Department of Linguistics',
        'SPOLS' =>  'Charles and Louise Travers Department of Political Science',
        'SWOME' =>  'Department of Gender and Women\'s Studies',
        'SYPSY' =>  'Department of Psychology',
        'SZANT' =>  'Department of Anthropology'
      }
    end
  end
end
