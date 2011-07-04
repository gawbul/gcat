#!/usr/bin/env python

'''
get_ensembl.py
A script to retrieve the latest EnsEMBL release MySQL data from the EnsEMBL ftp server
Coded by Steve Moss
gawbul@gmail.com
20th April 2011
'''

# imports
from ftplib import FTP
from time import time, strftime
import subprocess
import getpass
import re, os, sys
import MySQLdb
from colorama import Fore, Style, init
init(autoreset=True) # automatically reset colorama styles etc

# setup some variables
# variables for FTP connection
ftp_host = 'ftp.ensembl.org'
ftp_user = 'anonymous'
ftp_pass = ''
ftp_path = '/pub/current_mysql'

# variables for MySQL connection
sql_host = 'localhost'
sql_port = '3306'
sql_user = 'root'
sql_pass = getpass.getpass(Fore.CYAN + Style.BRIGHT + "\nPlease enter your MySQL password:" + Fore.RESET)

# other variables
data_dir = '/Volumes/DATA/current_mysql'

# start time
start_time = time()

'''
FTP stuff here
'''
print Style.BRIGHT + "\nRetrieving file listings from FTP...\n"

# connect to ftp
ensembl_ftp = FTP(ftp_host) # open connection
ensembl_ftp.login(ftp_user, ftp_pass) # login
ensembl_ftp.cwd(ftp_path) # change to MySQL path

# retrieve directories
ftp_struct = {} # setup dict to store data
dirs = ensembl_ftp.nlst()
for dir in dirs:
	# match only core + ensembl ancestral, compara and ontology dbs if need be
	# remove if and adjust whitespace to retrieve everything
	if re.match("[a-z]+_[a-z]+_core_[0-9]{2}_\w+", dir) or re.match("(^ensembl_[aco][a-z]{6,8}_[0-9]{2}$)", dir):
	# if re.match("^[a-z]+_[a-z]+_[a-z]+_[0-9]{2}_\w+$", dir) or re.match("(^ensembl_[aco][a-z]{6,8}_[0-9]{2}$)", dir):
		print dir
		new_path = os.path.join(ftp_path, dir) # build new path
		ensembl_ftp.cwd(new_path) # change to new path
		files = ensembl_ftp.nlst() # retrieve file listing
		ftp_struct[dir] = files
	
# close ftp connection and quit
ensembl_ftp.quit()

'''
WGET stuff here
'''
print Style.BRIGHT + "\nRetrieving files...\n"
# get files
os.chdir(data_dir) # change to data_dir
keys = ftp_struct.keys() # retrieve all dict keys
keys.sort() # sort alphabetically
for key in keys:
	if not os.path.exists(key):
		os.mkdir(key) # create directory if doesn't exist
	files = ftp_struct[key] # retrieve values (files) from dict
	print key
	for file in files:
		check_file_path = os.path.join(data_dir, key, file[:-3]) # build file path
		if not os.path.exists(check_file_path):
			file_path = os.path.join(data_dir, key) # build file path
			url_path = os.path.join(ftp_path, key, file) # build ftp url
			os.chdir(file_path) # change to file path
			p = subprocess.Popen(["wget", "-t", "0", "-c", "-N", "-nv", "ftp://" + ftp_host + url_path])
			p.wait() # wait for process to finish
	os.chdir(data_dir) # change back to data directory

'''
GUnzip stuff here
'''
print Style.BRIGHT + "\nExtracting files...\n"
os.chdir(data_dir) # change to data_dir
for key in keys:
	print key
	files = ftp_struct[key] # retrieve values (files) from dict
	for file in files:
		check_file_path = os.path.join(data_dir, key, file[:-3]) # build file path
		if not os.path.exists(check_file_path):
			file_path = os.path.join(data_dir, key) # build file path
			os.chdir(file_path)
			p = subprocess.Popen(["gunzip", "-dfq", file])
			p.wait() # wait for process to end
	os.chdir(data_dir)

"""
MySQL import here
"""
print Style.BRIGHT + "\nImporting to MySQL database...\n"
os.chdir(data_dir) # change to data_dir
for key in keys:
	print key
	# create database if not exists
	db = MySQLdb.connect(host=sql_host, port=int(sql_port), user=sql_user, passwd=sql_pass)
	cursor = db.cursor()
	cursor.execute("DROP DATABASE IF EXISTS " + key)
	cursor.execute("CREATE DATABASE IF NOT EXISTS " + key)
	cursor.close()
	# create tables
	sql_file_path = os.path.join(data_dir, key, key + ".sql") # build file path
	os.system("mysql -h " + sql_host + " -u " + sql_user + " -P " + sql_port + " -p" + sql_pass + " " + key + " < " + sql_file_path)
	files = ftp_struct[key] # retrieve values (files) from dict
	for file in files:
		if not file[:-3] == "CHECKSUMS" and not file[:-7] == key:
			file_path = os.path.join(data_dir, key) # build file path
			os.chdir(file_path)
			# import data
			p = subprocess.Popen(["mysqlimport", "-h", sql_host, "-u", sql_user, "-P", sql_port, "--password=" + sql_pass, "--fields_escaped_by=\\\\", key, "-L", file[:-3]])
			p.wait() # wait for process to end
	os.chdir(data_dir)
	
# end time
end_time = time()

# calculate time taken
total_time = end_time - start_time
days, remainder = divmod(total_time, 86400)
hours, remainder = divmod(remainder, 3600)
minutes, seconds = divmod(remainder, 60)
print Fore.YELLOW + Style.BRIGHT + 'Finished in: %d days %d hrs %d mins %d secs' % (days, hours, minutes, seconds)