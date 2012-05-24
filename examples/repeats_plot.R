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

# load all genome repeats class data
human <- read.csv(paste(home, '/Dropbox/PhD/Research/Development/gcat/data/homo_sapiens/grepeats.csv', sep=''))
chimp <- read.csv(paste(home, '/Dropbox/PhD/Research/Development/gcat/data/pan_troglodytes/grepeats.csv', sep=''))
gorilla <- read.csv(paste(home, '/Dropbox/PhD/Research/Development/gcat/data/gorilla_gorilla/grepeats.csv', sep=''))
orangutan <- read.csv(paste(home, '/Dropbox/PhD/Research/Development/gcat/data/pongo_abelii/grepeats.csv', sep=''))
baboon <- read.csv(paste(home, '/Dropbox/PhD/Research/Development/gcat/data/nomascus_leucogenys/grepeats.csv', sep=''))

# create list of all species data frames
all_spp <- list(human, chimp, gorilla, orangutan, baboon)

# change first column name to uniform "repclass" for each df in list
all_spp <- lapply(all_spp, function(x) {names(x)[1] <- "repclass" ; return(x)})

# merge data frames by repeat class column
data <- Reduce(function(x,y) {merge(x, y, by="repclass", all=T)}, all_spp)

# convert all NAs to 0
data[is.na(data)] <- 0

# check out data
attach(data)
names(data)
summary(data)
class(data)
head(data)
tail(data)

# create condensed list of repeat classes - discard everything from the / onwards and filter out ?s
rep_list <- list(sapply(strsplit(as.character(data[,1]), "/"), function(x) gsub("?", "", x[1], fixed=T)))
#rep_list <- list(sapply(strsplit(as.character(data[,1]), "/"), function(x)  {if (is.na(x[2])) x[2] <- x[1]; gsub("?", "", x[2], fixed=T)}))
#list(sapply(strsplit(as.character(data[,1]), "/"), function(x)  {if (is.na(x[2])) x[2] <- x[1]; gsub("?", "", x[2], fixed=T)}))
 list(sapply(strsplit(unlist(rep_list), "-"), function(x)  {if (is.na(x[2])) x[2] <- x[1]; gsub("?", "", x[2], fixed=T)}))

unlist(rep_list)
unique(unlist(rep_list))

# adapt data for barplot by aggregating all repeat classes and summing their values
data <- aggregate(data[-1], by=rep_list, sum) # aggregate by repeat type and sum
rownames(data) <- data[,1] # set row names
data[,1] <- NULL # remove the repeat class column

# create check for odd and even functions
is.even <- function(x) x %% 2 == 0
is.odd <- function(x) x %% 2 != 0

# create odd and even lists
nums <- c(1:length(data))
even_nums <- nums[is.even(nums)]
odd_nums <- nums[is.odd(nums)]
head(data[,even_nums])
head(data[,odd_nums])

# set colours and names
spp_cols <- as.character(sample(colors()[grep("light|white|grey|gray|ivory|cream|snow|seashell|yellow|lace|linen",colors(), invert=T)], nrow(data), replace=F)) # choose random sample of only dark, deep or medium colours
#spp_cols <- as.character(sample(colors()[grep("dark|medium|deep",colors())], nrow(data), replace=F)) # choose random sample of only dark, deep or medium colours
spp_names <- c("Human", "Chimp", "Gorilla", "Orangutan", "Gibbon")

# roundup function
roundup <- function(x) (ceiling(x / 10^(nchar(x) - 2)) * 10^(nchar(x) - 2)) # round numbers up to the nearest 10 ^ (number length minus 2)

# turn off scientific notation
options(scipen=999) # sets number of 0s before convert to scientific notation

# create new graphics device
if (.Platform$OS.type == "unix") {
	quartz()
} else {
	windows()
}

# setup barplot pdf filename
#pdf(file=paste(home, '/Dropbox/PhD/Research/Development/gcat/examples/grepeats_barplot.pdf', sep=''), width=18, height=12)

# correct margins and use a 1 by 2 row
par(mfrow=c(1,2), mar=c(5,5,6,10), xpd=NA) # xpd=NA allows us to draw in the outer margin (used for legend)

# work out max values
ymax <- roundup(max(apply(data[,even_nums], 2, sum))) # use roundup to get max value for axis
ydiv <-  1 * 10 ^ (nchar(ymax) - 2) # work out what the 10 ^ (number length minus 2) is
ytick <- ymax / ydiv # use ymax and ydiv to get max value for the axis

# work out label text - we using custom axis with ytick as the max and add label text accordingly
if (ydiv %% 1000000000 == 0) {
	ytext <- "Length (Bbp)"
} else if (ydiv %% 1000000 == 0) {
	ytext <- "Length (Mbp)"	
} else if (ydiv %% 1000 == 0) {
	ytext <- "Length (Kbp)"	
} else {
	ytext <- "Length (bp)"	
}

# plot the lengths barplot
barplot(as.matrix(data[,even_nums]), beside=F, names.arg=spp_names, axes=F, col=spp_cols, space=0.1, cex=0.8, ylim=c(0, ymax), cex.axis=0.8, xlab="Species",  ylab=ytext, main="Length of Repeats by Class and Species")
legend(par("usr")[2], par("usr")[4], legend=rownames(data), cex=0.8, fill=spp_cols) # plot legend using usr coordinates
axis(2, at=seq(0,ymax, by=ymax/10), labels=seq(0,ytick, by=ytick/10), las=2) # plot axis using ytick and las = horizontal

# work out max values
ymax <- roundup(max(apply(data[,odd_nums], 2, sum))) # use roundup to get max value for axis
ydiv <-  1 * 10 ^ (nchar(ymax) - 2) # work out what the 10 ^ (number length minus 2) is
ytick <- ymax / ydiv # use ymax and ydiv to get max value for the axis

# work out label text - we using custom axis with ytick as the max and add label text accordingl
if (ydiv %% 1000000000 == 0) {
	ytext <- "Number (Billions)"
} else if (ydiv %% 1000000 == 0) {
	ytext <- "Number (Millions)"	
} else if (ydiv %% 1000 == 0) {
	ytext <- "Number (Thousands)"	
} else {
	ytext <- "Number"	
}

# plot the counts barplot
barplot(as.matrix(data[,odd_nums]), beside=F, names.arg=spp_names, axes=F, col=spp_cols, space=0.1, cex=0.8, ylim=c(0, ymax), cex.axis=0.8, xlab="Species", ylab=ytext, main="Number of Repeats by Class and Species")
legend(par("usr")[2], par("usr")[4], legend=rownames(data), cex=0.8, fill=spp_cols) # plot legend using usr coordinates
axis(2, at=seq(0,ymax, by=ymax/10), labels=seq(0,ytick, by=ytick/10), las=2) # plot axis using ytick and las = horizontal
#dev.off()