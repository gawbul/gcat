data = read.csv('/Users/stevemoss/Dropbox/PhD/Research/Development/gcat/data/ciona_intestinalis/grepeats.csv')
attach(data)
names(data)
rownames(data) <- data[,1]
data[,1] <- NULL

data
t(data)

cols <- as.character(sample(colours(), 1, replace=F))
barplot(as.matrix(data), beside=F, names.arg=, col=heat.colors(9), space=0.1, cex=0.8, cex.axis=0.8, las=1, ylab="Total")
legend("topleft", legend=saccharomyces_cerevisiae.desc, inset=0.1, cex=0.8, fill=heat.colors(9))

freqs <- read.csv('/Users/stevemoss/Dropbox/PhD/Research/Development/gcat/data/grepeats_freqs_all.csv', header=T)
freqs
freqs(is.na(freqs)) <- NULL
attach(freqs)
names(freqs)

max(na.omit(ciona_intestinalis.size))
test <- as.character(sample(topo.colors(512), 5, replace=F))

?topo.colors
cols <- c("red", "green", "blue")
cols
summary(cols)
test
class(test)
summary(test)