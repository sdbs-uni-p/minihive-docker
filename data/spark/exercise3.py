fileData = sc.textFile('file:///home/minihive/spark/barkly.csv')
fileData.collect()

inputRDD = fileData.map(lambda line: (line.split('\t')[0], line.split('\t')[1]))
inputRDD.collect()

hobbiesRDD = inputRDD.map(lambda doc: (doc[0], doc[1].split('|')))
hobbiesRDD.collect()

hobbyRDD = hobbiesRDD.flatMapValues(lambda x: x)
hobbyRDD.collect()

hobbyInvRDD = hobbyRDD.map(lambda x: (x[1], x[0]))
hobbyInvRDD.collect()

groupByIdRDD = hobbyInvRDD.groupByKey()
groupByIdRDD.collect()

invertedIndexRDD = groupByIdRDD.map(lambda x: (x[0], set(x[1])))
invertedIndexRDD.collect()

