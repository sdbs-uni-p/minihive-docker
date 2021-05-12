
file = sc.textFile('file:///home/minihive/spark/preferences.csv')

file.map(lambda x: (x.split(',')[0], x.split(',')[1]))
    .map(lambda x: (x[0], x[1].split('|')))
    .flatMapValues(lambda x: x)
    .map(lambda x: (x[1], x[0]))
    .groupByKey()
    .map(lambda x: (x[0], [y for y in x[1]])).collect()

[('folk', ['mary']), 
 ('pop', ['bill']), 
 ('jazz', ['bill', 'jany']), 
 ('rock', ['jany', 'mary'])
]

