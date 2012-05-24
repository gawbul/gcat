# start with a fresh sheet ;)
rm(list = ls(all = TRUE)) # clear workspace
graphics.off() # turn off graphics

# detect platform and set home directory accordingly
if (.Platform$OS.type == "unix") {
	home <- Sys.getenv('HOME')
} else {
	home <- Sys.getenv('USERPROFILE')
	if (home == "") {
		home <- paste(Sys.getenv('HOMEDRIVE'), Sys.getenv('HOMEPATH'), sep = '')
	}
}

#############################
# PLOT GROUP FREQUENCY DATA #
#############################

# load freqs file
gene_data <- read.csv(paste(home, '/Dropbox/PhD/Research/Development/gcat/data/mus_musculus/gene_structure.csv', sep=''),header=T)

# check out data
summary(gene_data)
names(gene_data)
attach(gene_data)
class(gene_data)
head(gene_data)
tail(gene_data)

# turn off scientific notation
options(scipen=7) # sets number of 0s before convert to scientific notation

# open a new default device.
pdf(file=paste(home, '/Dropbox/PhD/Research/Development/gcat/examples/gene_structure.pdf', sep=''), width=12, height=12)
#png(file=paste(home, '/Dropbox/PhD/Research/Development/gcat/examples/gene_structure.png', sep=''), width=1280, height=1280)
get(getOption("device"))()

# split screen into 1 row and 2 columns
# assigned as screen 1 and 2
split.screen(figs = c(1, 2))

# split screen 1 into 3 rows and 1 column
# assigned as screens 3, 4, and 5
split.screen(figs=c(3, 1), screen=1)

# split screen 2 into 2 rows and 1 columns
# assigned as screens 6 and 7
split.screen(figs=c(2, 1), screen=2)

# individual plots of frequency
screen(3)
plot(table(mus_musculus.5putr_size), main="a)", type="l", col="red", log="x", xlim=c(1,10000), ylim=c(0,125), xlab="Log 5'-UTR Size (bp)", ylab="Frequency", xaxt="n")
axis(side=1, at=c(1,10,100,1000,10000))
screen(4)
plot(table(mus_musculus.coding_size), main="b)", type="l", col="green", ylim=c(0,60), xlim=c(1,1000000), log="x", xlab="Log CDS Size (bp)", ylab="Frequency", xaxt="n")
axis(side=1, at=c(1,10,100,1000,10000,100000,1000000))
screen(5)
plot(table(mus_musculus.3putr_size), main="c)", type="l", col="blue", log="x", ylim=c(0,60), xlim=c(1,10000), xlab="Log 3'-UTR Size (bp)", ylab="Frequency", xaxt="n")
axis(side=1, at=c(1,10,100,1000,10000))
# scatterplot of 5' vs 3' UTR size
screen(6)
plot(mus_musculus.5putr_size,mus_musculus.3putr_size, main="d)", col=c("purple"), log="xy", xlab="Log 5'-UTR Size (bp)", ylab="Log 3'-UTR Size (bp)", xlim=c(1,10000), ylim=c(1,15000), xaxt="n", yaxt="n")
axis(side=1,  at=c(1,10,100,1000,10000))
axis(side=2, at=c(1,10,100,1000,10000))
# scatterplot of 5'+3' UTR vs coding length
screen(7)
plot(mus_musculus.intron_size, (mus_musculus.5putr_size+mus_musculus.3putr_size), main="e)", col=c("orange"), log="xy", xlab="Log Intron Size (bp)", ylab="Log 5'-UTR Size + 3'-UTR Size (bp)", xlim=c(1,10000000), ylim=c(1,100000), xaxt="n", yaxt="n")
axis(side=1,  at=c(1,10,100,1000,10000,100000,1000000,10000000))
axis(side=2, at=c(1,10,100,1000,10000,100000))
# close all screens
close.screen(all=T)

# device off
dev.off()



# do spearman's to test correlation
cor.test(caenorhabditis_elegans.5putr_size, caenorhabditis_elegans.3putr_size, method=c("spearman"))

# non-parametric paired t-test equivalent
wilcox.test(caenorhabditis_elegans.5putr_size, caenorhabditis_elegans.3putr_size, paired=T)

# non-parametric ANOVA equivalent
kruskal.test()

??spearmans