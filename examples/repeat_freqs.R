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
freqs_data <- read.csv(paste(home, '/Dropbox/PhD/Research/Development/gcat/data/grepeats_freqs_all_5397205320.csv', sep=''),header=T)

# remove any data < 11 - all dust
freqs_data <- freqs_data[-1:-3,]

# check out data
summary(freqs_data)
names(freqs_data)
attach(freqs_data)
class(freqs_data)
head(freqs_data)
tail(freqs_data)

# create check for odd and even functions
is.even <- function(x) x %% 2 == 0
is.odd <- function(x) x %% 2 != 0

# create odd and even lists
nums <- c(1:length(freqs_data))
odd_nums <- nums[is.odd(nums)]
even_nums <- nums[is.even(nums)]
head(freqs_data[,odd_nums])
head(freqs_data[,even_nums])

# roundup function
roundup <- function(x) (ceiling(x / 10^(nchar(x) - 2)) * 10^(nchar(x) - 2)) # round numbers up to the nearest 10 ^ (number length minus 2)

# work out max values
ymax <- roundup(max(na.omit(freqs_data[,even_nums])))
xmax <-roundup(max(apply(na.omit(as.matrix(freqs_data[,odd_nums])), 2, function(x) quantile(x, .75))))

# get some colors
spp_cols <- sample(colors()[grep("dark|deep|medium",colors(), invert=F)], length(nums)/2, replace=F)
#spp_cols <- sample(colors()[grep("light|white|grey|gray|ivory|cream|snow|seashell|yellow",colors(), invert=T)], length(nums)/2, replace=F)

#pdf(file=paste(home, '/Dropbox/PhD/Research/Development/gcat/data/grepeats_freqs.pdf', sep=''), width=12, height=12)
plot(homo_sapiens.size, homo_sapiens.freqs, type="l", xlim=c(10,400), ylim=c(0,ymax), xlab="Size (bp)", ylab="Frequency", main="Frequency distribution of genome wide repeat elements in 5 primates", col=spp_cols[1])
lines(pan_troglodytes.size, pan_troglodytes.freqs, col=spp_cols[2])
lines(gorilla_gorilla.size, gorilla_gorilla.freqs, col=spp_cols[3])
lines(pongo_abelii.size, pongo_abelii.freqs, col=spp_cols[4])
lines(nomascus_leucogenys.size, nomascus_leucogenys.freqs, col=spp_cols[5])
legend("topright", inset=0.01, legend=c("Human", "Chimp", "Gorilla", "Orangutan", "Gibbon"), col=spp_cols, lty=1, lwd=2)
#dev.off()

#################################
# END PLOT GROUP FREQUENCY DATA #
#################################

##############################
# PLOT NON-REDUNDANT REPEATS #
##############################

# load all genome repeats class data
hs_freqs_data <- read.csv(paste(home, '/Dropbox/PhD/Research/Development/gcat/data/homo_sapiens_repeats.freqs', sep=''),header=F)
pt_freqs_data <- read.csv(paste(home, '/Dropbox/PhD/Research/Development/gcat/data/pan_troglodytes_repeats.freqs', sep=''),header=F)
gg_freqs_data <- read.csv(paste(home, '/Dropbox/PhD/Research/Development/gcat/data/gorilla_gorilla_repeats.freqs', sep=''),header=F)
pa_freqs_data <- read.csv(paste(home, '/Dropbox/PhD/Research/Development/gcat/data/pongo_abelii_repeats.freqs', sep=''),header=F)
nl_freqs_data <- read.csv(paste(home, '/Dropbox/PhD/Research/Development/gcat/data/nomascus_leucogenys_repeats.freqs', sep=''),header=F)
mm_freqs_data <- read.csv(paste(home, '/Dropbox/PhD/Research/Development/gcat/data/mus_musculus_repeats.freqs', sep=''),header=F)

# plot repeats from raw counts using table
#pdf(file=paste(home, '/Dropbox/PhD/Research/Development/gcat/data/grepeats_freqs.pdf', sep=''), width=12, height=12)
plot(table(hs_freqs_data), xlim=c(0,400), ylim=c(1750,200000), axes=F, log="y", type="l", col="red", main="Frequency distribution plot of genome-wide repeat elements", xlab="Size (bp)", ylab="Frequency")
lines(table(pt_freqs_data), col="green", type="l")
lines(table(gg_freqs_data), col="purple", type="l")
lines(table(pa_freqs_data), col="orange", type="l")
lines(table(nl_freqs_data), col="blue", type="l")
lines(table(mm_freqs_data), col="black", type="l")
axis(at=seq(0,400, by=50), labels=seq(0,400, by=50), side=1)
axis(at=c(2000, 5000, 10000, 20000, 50000, 100000, 200000), labels=c(2000, 5000, 10000, 20000, 50000, 100000, 200000), side=2)
legend("topright", legend=c("Human", "Chimp", "Gorilla", "Orangutan", "Gibbon", "Mouse"), col=c("red", "green", "purple", "orange", "blue", "black"), lty=1, lwd=2, inset=0.01)
#dev.off()

##################################
# END PLOT NON-REDUNDANT REPEATS #
##################################