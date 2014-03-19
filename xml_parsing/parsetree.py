from collections import deque        
import re

#from docx import *
from xmlparse import *
import ftplib
##from docx import *
from lxml import etree
try:
    from PIL import Image
except ImportError:
    import Image
import zipfile

##make master xml document in another file
####http://lxml.de/index.html#documentation
server = 'developexchange.com'
ftp = ftplib.FTP(server)
ftp.login('develop_user','13!DEVELOP54311')
ftp.cwd('data')
directories = ftp.nlst()
global masterxml
masterxml = 'masterXML.xml'

def getExchangeXML():
    for year in directories:
        print ("Main ==> " + year )
        foundyear = re.match('[0-9]{4}',year)
        #if type(foundyear) != 'NoneType':
        if foundyear:
            ftp.cwd(year)
            for termdirec in ftp.nlst():
                print ("Checking " + year + ": " + termdirec)
                term = 'Fall [0-9]{4}|Summer [0-9]{4}|Spring [0-9]{4}|[0-9]{4} Fall (?![a-zA-Z])|[0-9]{4} Spring (?![a-zA-Z])|[0-9]{4} Summer (?![a-zA-Z])'
##                if re.search(term,termdirec,re.I) != 'NoneType':
                if re.search(term,termdirec,re.I):
                    print("Folder: " +year + "/" +  "/"  + termdirec)
                    filetree(termdirec,ftp) #Enter folders and look for all project summaries 
                    ftp.cwd('..')
            ftp.cwd('..')
            
def filetree(directory, ftp):
    # I need to make sure that the ftplib object exists
    # or I could just pass it as an argument which also works
    # ahh initialize search

    visitexchange = deque([directory]) #Was trying to do a breadth first search but didn't work 
    v_finaldocx = []
    for exchangefiles in visitexchange:
        print ('---' + exchangefiles)
        ftp.cwd(exchangefiles)   # enter directory
        files  = ftp.nlst()
        strfiles = ' '.join(files)  
        # making sure I am in a folder if you aren't then look for files that are .DOC or .DOCX
        projectdocxs = re.findall(r'\w+.*(?<=\.docx)|\w+.*(?<=\.doc)',strfiles)
        if projectdocxs:
            docxlist = re.split(';',';'.join(files))
            for docx in docxlist:
                boolean = re.findall('Project.*final',docx,re.I)    
                if boolean:
                    print'WILL ADD : '+ docx + 'TO MASTERXML.XML'
                    v_finaldocx.append(docx)                   
                    fhandle = open(docx,'wb')
                    ftp.retrbinary('RETR ' + docx,fhandle.write)
                    fhandle.close()
                    # do xml processing return updated sheet
                        #masterxml = 'masterXML.xml'
                        #masterxml = xmlprocessing('finalprojectsummaries.docx',masterxml)

        # if folder you are currently in (EXCHANGEFILES) contains other subfolders find those folders
        # and enter them and perfomr the filetree search again 
        else:
        # Only look at folders i.e. things without extensions
            for enterfolder in files:
                foldermatch = re.findall(r'\.[aA-zZ0-9_]{3,4}',enterfolder)
                if not foldermatch:
                    print(enterfolder)
                    filetree(enterfolder,ftp)
                    ftp.cwd('..')
                    
