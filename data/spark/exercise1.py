fileData = sc.textFile('file:///home/minihive/spark/barkly.csv')

# Print content (check if load was successful)
fileData.collect()

# (Prepare to lazily) load the data.
inputRDD = fileData.map(lambda line: (line.split('\t')[0], line.split('\t')[1]))
# [(u'1', u'fetch|frisbee|chasing squirrels'), 
#  (u'2', u'fetch|chew'), 
#  (u'3', u'frisbee|snooze'), 
#  (u'4', u'fetch|frisbee')]


# Spark code to build inverted index


# Step 1: Convert to RDD[(survey_number, hobby)] using a flatMap
hobbiesRDD = inputRDD.map(lambda doc: (doc[0], doc[1].split('|')))

#[(u'1', [u'fetch', u'frisbee', u'chasing squirrels']), 
# (u'2', [u'fetch', u'chew']), 
# (u'3', [u'frisbee', u'snooze']), ...


hobbyRDD = hobbiesRDD.flatMapValues(lambda x: x)

# [(u'1', u'fetch'), (u'1', u'frisbee'), (u'1', u'chasing squirrels'), 
#  (u'2', u'fetch'), (u'2', u'chew'), ... ]


# Step 2: convert to RDD[(hobby, survey_number)] using a map

hobbyInvRDD = hobbyRDD.map(lambda x: (x[1], x[0]))

# [(u'fetch', u'1'), #  (u'frisbee', u'1'), ... (u'chew', u'2'), ...]


# Step 3: Convert to RDD[(hobby, set(survey_number) )] using groupByKey

groupByIdRDD = hobbyInvRDD.groupByKey()

# [(u'snooze', <pyspark.resultiterable.ResultIterable object...>),  ...]

# Step 4: Make the list a set
invertedIndexRDD = groupByIdRDD.map(lambda x: (x[0], set(x[1])))
invertedIndexRDD.collect()
# [(u'snooze', set([u'3'])), (u'chew', set([u'2'])), ... ]
 
