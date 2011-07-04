"""
A script to parse the WindowMasker interval file output to count the numbers of repeats and their total length.
Coded by Steve Moss
Email: gawbul@gmail.com
Date: 24th May 2011

"""

# imports
import os, sys, re, time
from scipy import stats
import numpy

# variables
intron_count = 0
repeat_count = 0
repeat_length = 0
cum_rep_len = 0
unique_intron_sizes = []
non_rep_intron_sizes = []
rep_intron_sizes = []
header = 0

# regex
header_regex = re.compile("^>.*?$")
re_regex = re.compile("^[0-9]+\s+-\s+[0-9]+$")

# start time
start_time = time.time()

# get filename from args
filenames = sys.argv[1:]

print "\nProcessing WindowMasker interval file output..."

for filename in filenames:
	# open file and iterate through each line in turn
	if not os.path.exists(filename):
		print "File \'%s\' not found" % filename
	print "\nParsing %s..." % filename
	infile = open(filename, "r")
	while 1:
		line = infile.readline()
		if not line:
			break
		else:
			# match a fasta header line
			if header_regex.match(line):
				# is this the first sequence, if not then calculate the unique intron size
				if not cum_rep_len == 0:
					unique_intron_sizes.append(intron_size - cum_rep_len)
					rep_intron_sizes.append(intron_size - cum_rep_len)
				if header == 1:
					unique_intron_sizes.append(intron_size)
					non_rep_intron_sizes.append(intron_size)
				header = 1			
				intron_count += 1
				header_parts = line.split()
				intron_size = int(header_parts[5])
				cum_rep_len = 0
			# match a repeat element range
			elif re_regex.match(line):
				header = 0
				repeat_count += 1
				start, end = line.split(" - ")
				total = (int(end) - int(start)) + 1
				cum_rep_len += total
				repeat_length += total
	# append last sequence (no more header lines to process this)
	if not cum_rep_len == 0:
		unique_intron_sizes.append(intron_size - cum_rep_len)
		rep_intron_sizes.append(intron_size - cum_rep_len)
	if header == 1:
		unique_intron_sizes.append(intron_size)
		non_rep_intron_sizes.append(intron_size)
	infile.close()

	# build output filenames
	filename_parts = filename.split(".")
	output = filename_parts[0] + "_" + filename_parts[1] + "_unique.csv"
	output2 = filename_parts[0] + "_" + filename_parts[1] + "_nonre.csv"
	output3 = filename_parts[0] + "_" + filename_parts[1] + "_re.csv"

	unique_intron_sizes = filter (lambda x: x != 0, unique_intron_sizes)
	rep_intron_sizes = filter (lambda x: x != 0, rep_intron_sizes)
	
	# write out the raw unique intron sizes
	outfile = open(output, "w")
	outfile.write("unique_intron_sizes.raw\n")
	for size in unique_intron_sizes:
		outfile.write(str(size) + "\n")
	outfile.close()
	
	# write out the raw non repeat intron sizes
	outfile = open(output2, "w")
	outfile.write("intron_sizes.raw\n")
	for size in non_rep_intron_sizes:
		outfile.write(str(size) + "\n")
	outfile.close()

	# write out the raw repeat intron sizes
	outfile = open(output3, "w")
	outfile.write("intron_sizes.raw\n")
	for size in rep_intron_sizes:
		outfile.write(str(size) + "\n")
	outfile.close()	

	# print out some information
	print "Number of introns: %d" % intron_count
	print "Repeat count: %d" % repeat_count
	print "Repeat length: %d" % repeat_length
	print "Repeats per intron: %.2f" % (float(repeat_count) / float(intron_count))
	print "Number of introns containing repeats: %d" % (len(unique_intron_sizes) - len(non_rep_intron_sizes))
	print "Raw unique intron sizes outputted to %s" % output
	print "\nNon repeat introns:"
	print "Count:", len(non_rep_intron_sizes)
	print "Max:", max(non_rep_intron_sizes)
	print "Min:", min(non_rep_intron_sizes)
	print "Mean: %.2f" % numpy.mean(non_rep_intron_sizes)
	print "Median: %d" % numpy.median(non_rep_intron_sizes)
	print "Mode: %d" % stats.mode(non_rep_intron_sizes)[0]
	print "GMean: %.2f" % stats.gmean(non_rep_intron_sizes)
	print "HMean: %.2f" % stats.hmean(non_rep_intron_sizes)
	print "\nRepeat introns:"
	print "Count:", len(rep_intron_sizes)
	print "Max:", max(rep_intron_sizes)
	print "Min:", min(rep_intron_sizes)
	print "Mean: %.2f" % numpy.mean(rep_intron_sizes)
	print "Median %d" % numpy.median(rep_intron_sizes)
	print "Mode: %d" % stats.mode(rep_intron_sizes)[0]
	print "GMean: %.2f" % stats.gmean(rep_intron_sizes)
	print "HMean: %.2f" % stats.hmean(rep_intron_sizes)
	
	intron_count = 0
	repeat_count = 0
	repeat_length = 0
	cum_rep_len = 0
	header = 0
	unique_intron_sizes = []
	non_rep_intron_sizes = []
	rep_intron_sizes = []
	
# end time and calculate total
end_time = time.time()
total_time = end_time - start_time

print "Finished in %d seconds" % total_time