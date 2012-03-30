data = read.csv('/Users/stevemoss/Dropbox/PhD/Research/Development/gcat/data/grepeats_raw_all.csv')
attach(data)
names(data)
rownames(data) <- data[,1]
data[,1] <- NULL

data
t(data)

cols <- as.character(sample(colors()[grep("dark|deep|medium",colors())], 1, replace=F))

colors()[grep("dark|deep|medium",colors())]

barplot(as.matrix(data), beside=F, names.arg=, col=colors()[grep("dark|deep|medium",colors())], space=0.1, cex=0.8, cex.axis=0.8, las=1, ylab="Total")

legend("topleft", legend=ciona_intestinalis.desc, inset=0.1, cex=0.8, fill=colors()[grep("dark|deep|medium",colors())])

