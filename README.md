#  <#Title#>

todo

- load example data into context
- preview view with example data 

Review page
 
Data loader


- each data should have english and japanese (in full kanji) - there should be a feature to toggle if each kanji is shown based on JLPT level

- each data should be loaded from a source file. for instance a user can put in a csv file download link and it will download that into the card swift data store
- each data row should also have tag information, i.e. the JLPT level or category. i.e. N5, Family or N4, Weather or just N3...
- when loading a new file the user inputs a source name and the file url

- there should be additional options already pre selected. these options tell the importer whether to create a recall and recognition copy of the card. i.e. english to japanese and japanese to english


Configuration page

- on the configuration page, the user can then select or deselect data sources imported, and select and deselect tags from the sources.
- configure how many words are loaded each day
- the user can also select the level of kanji shown on the cards. if N5 is selected the kanji which are not N5 are converted/translated to hirigana


Data update:
- data in the cards should only have english and japanese (kanji) at card review load time, the kanji is potentially converted to hirigana depending on the configuration.
- Also cardtype is now RECOGNITION and RECALL
