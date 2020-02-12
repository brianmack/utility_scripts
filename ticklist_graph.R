
require(ggplot2)

d = read.csv("ticks.csv")

# clean up data NA's and delete irrelevant rows
d = d[-which(!(d$Style %in% c("Lead", "TR", "Follow"))),]
d$Lead.Style[which(is.na(d$Lead.Style))] == "Redpoint" 
d = d[-which(!(d$Route.Type %in% c("Sport", "Trad"))),]

# change to character in order to do some cleaning of things like '5.7 R'
s =as.character(d$Rating)
# useful for cleaning and also for ordering factors later
low_grade_strings = c("5.1", "5.2", "5.3", "5.4","5.5","5.6","5.7","5.8","5.9")

# optional here; uncomment to remove rows which have low grades if you 
# don't want your plot to go all the way down to 5.1

#d = d[-which(s %in% low_grades), ] 
#s = s[-which(s %in% low_grades)] 
#grade_levels = levels(d$Rating)
#grade_levels = grade_levels[-which(grade_levels %in% low_grades)]
#grade_levels = c(low_grades, grade_levels)
#d$Rating = factor(d$Rating, levels=grade_levels)
#d = d[-which(d$Lead.Style=="Fell/Hung"),]
#s = gsub(x=s, pattern="5.9", replacement="5.09")
#s[low_grades] = gsub(x=s[low_grades], pattern=" .+$", replacement="")

tmp = gsub(x=s, pattern=" .+$", replacement="")
tmp = gsub(x=tmp, pattern="\\+", replacement="")
tmp = gsub(x=tmp, pattern="-", replacement="")
low_grades = as.logical(apply(sapply(tmp, grepl, low_grade_strings), 2, max))

s = gsub(x=s, pattern=" .+$", replacement="")

# some debug printing to make sure all the text cleanup is handled
#print(s[low_grades])
#print(s[-low_grades])


#s = gsub(x=s, pattern=" .+$", replacement="")
s = gsub(x=s, pattern="a/b", replacement="b")
s = gsub(x=s, pattern="b/c", replacement="c")
s = gsub(x=s, pattern="c/d", replacement="d")
s[!low_grades] = gsub(x=s[!low_grades], pattern="\\+", replacement="d")
s[!low_grades] = gsub(x=s[!low_grades], pattern="-", replacement="a")
s[low_grades] = gsub(x=s[low_grades], pattern="\\+", replacement="")
s[low_grades] = gsub(x=s[low_grades], pattern="-", replacement="")
#s = gsub(x=s, pattern="-", replacement="a")
s = gsub(x=s, pattern="5.10$", replacement="5.10b")
s = gsub(x=s, pattern="5.11$", replacement="5.11b")
s = gsub(x=s, pattern="5.12$", replacement="5.12b")
#s = gsub(x=s, pattern="c/d", replacement=4)
#s = gsub(x=s, pattern="a", replacement=1)
#s = gsub(x=s, pattern="b", replacement=2)
#s = gsub(x=s, pattern="c", replacement=3)
#s = gsub(x=s, pattern="d", replacement=4)

d$Rating = factor(s, levels=c(
    "5.1",
    "5.2",
    "5.3",
    "5.4",
    "5.5",
    "5.6",
    "5.7",
    "5.8",
    "5.9",
    "5.10a",
    "5.10b",
    "5.10",
    "5.10c",
    "5.10d",
    "5.11a",
    "5.11b",
    "5.11",
    "5.11c",
    "5.11d",
    "5.12a",
    "5.12b"))

dt = as.Date(d$Date)
d$Date = dt

# set level orders
d$Style = factor(d$Style, levels=c("Lead", "Follow", "TR"))
d$Lead.Style = factor(d$Lead.Style, levels=c("Fell/Hung", "Redpoint", "Flash", "Onsight")) 

# generate the plot
p = (
    ggplot(d, aes(x=Date, y=Rating, col=Rating, shape=Style, alpha=Lead.Style)) + 
    geom_point(size=7, position="jitter") + 
    scale_x_date(date_breaks = "months" , date_labels = "%b") + 
    ggtitle("Outdoor Grades Progression 2019") + 
    theme(plot.title=element_text(hjust=0.5)) + 
    scale_alpha_manual(values=c(0.3, 0.7, 0.85, 1.0)) +
    scale_shape_manual(values=c(16, 3, 4)) +
    guides(col=F)
)

print("enter 'p' to view plot object")
