# start with a fresh sheet ;)
rm(list = ls(all = TRUE)) # clear workspace
graphics.off() # turn off graphics

# load all genome repeats class data
human <- read.csv('C:/Users/Steve/Dropbox/PhD/Research/Development/gcat/data/homo_sapiens/grepeats.csv')
chimp <- read.csv('C:/Users/Steve/Dropbox/PhD/Research/Development/gcat/data/pan_troglodytes/grepeats.csv')
gorilla <- read.csv('C:/Users/Steve/Dropbox/PhD/Research/Development/gcat/data/gorilla_gorilla/grepeats.csv')
orangutan <- read.csv('C:/Users/Steve/Dropbox/PhD/Research/Development/gcat/data/pongo_abelii/grepeats.csv')
baboon <- read.csv('C:/Users/Steve/Dropbox/PhD/Research/Development/gcat/data/nomascus_leucogenys/grepeats.csv')

# create list of all species data frames
all_spp <- list(human, chimp, gorilla, orangutan, baboon)

# change first column name to uniform "repclass" for each df in list
all_spp <- lapply(all_spp, function(x) {names(x)[1] <- "repclass" ; return(x)})

# merge data frames by repeat class
data <- Reduce(function(x,y) {merge(x, y, by="repclass", all=T)}, all_spp)

# convert all NAs to 0
data[is.na(data)] <- 0

# check out data
attach(data)
names(data)
summary(data)
class(data)
tail(data)

# create list of repeat classes
rep_list <- list(unlist(lapply(strsplit(as.character(data[,1]), "/"), function(x)  gsub("?", "", x[1], fixed=T))))
unlist(rep_list)
unique(unlist(rep_list))

# adapt data for barplot
data <- aggregate(data[-1], by=rep_list, sum) # aggregate by repeat type and sum
rownames(data) <- data[,1] # set row names
data[,1] <- NULL # remove the repeat class column

# create odd and even functions
is.even <- function(x) x %% 2 == 0
is.odd <- function(x) x %% 2 != 0

# create odd and even lists
nums <- c(1:length(data))
even_nums <- nums[is.even(nums)]
odd_nums <- nums[is.odd(nums)]
tail(data[,even_nums])
tail(data[,odd_nums])

# set colours and names
spp_cols <- as.character(sample(colors()[grep("dark|deep|medium",colors())], nrow(data), replace=F))
spp_names <- c("Human", "Chimp", "Gorilla", "Orangutan", "Baboon")

# plot the lengths barplot
par(mar=c(5,4,4,10), xpd=NA)
barplot(as.matrix(data[,even_nums]), beside=F, names.arg=spp_names, col=spp_cols, space=0.1, cex=0.8, cex.axis=0.8, las=1, xlab="Species", log="y", ylab="Length (bp)", main="Length of Repeats by Class and Species")
legend(par("usr")[2], par("usr")[4], legend=rownames(data), inset=0.1, cex=0.8, fill=spp_cols)
#dev.off()

# plot the counts barplot
barplot(as.matrix(data[,odd_nums]), beside=F, names.arg=spp_names, col=spp_cols, space=0.1, cex=0.8, cex.axis=0.8, las=1, xlab="Species", ylab="Number", main="Number of Repeats by Class and Species")
legend(par("usr")[2], par("usr")[4], legend=rownames(data), inset=0.1, cex=0.8, fill=spp_cols)
#dev.off()