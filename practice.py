#####################
numbers = list(range(100))
count = 0
for i in numbers:
	count = i+count
	
###############################
# List comprehensions
[expression in for loop condition]

#[i for i in list(rang(100))]	
#[i * 2 for i in list(rang(100))]	
#[i  for i in list(range(100)) if i %2 == 0 ]
[i  for i in list(range(100)) if i %2 == 0 ]
[0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 48, 50, 52, 54, 56, 58, 60, 62, 64, 66, 68, 70, 72, 74, 76, 78, 80, 82, 84, 86, 88, 90, 92, 94, 96, 98]

alist = ['python', 'ruby', 'shell']
[i.upper() for i in alist if i.startswith('p')]
['PYTHON']

# Nested comprehensions
[x * y for x in list(range(10)) for y in list(range(5))]
[0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 0, 2, 4, 6, 8, 0, 3, 6, 9, 12, 0, 4, 8, 12, 16, 0, 5, 10, 15, 20, 0, 6, 12, 18, 24, 0, 7, 14, 21, 28, 0, 8, 16, 24, 32, 0, 9, 18, 27, 36]
#####################################

# Split Method
myname = 'python language is good learning'
myname.split()
myList = myname.split()
myList
#task: count the number of words in a file.


mysubject = 'Python programming tutorials'

Split:
ip_address = 192.168.1.1
ip_address.split('.')

mylist = ["Python", "Programme"]
#convert list to string:

"-".join(mylist)

#Find:
mysubject.find('o')

################################################################################################################
##### Dictionaries: are accessed by keys not with the index(offest is like 1 to -1).
# unordered collections of arbitary objects. variable length, hetrogenous and nested.
#Mutable type (Mapping mutable). Dont use dict as variable.

employee = {} use curly braces which means creating dictionary.

d = {} # del d to delete dictionary

subjects = {'Python': 'Guido', 'Perl': 'Larry', 'Tcl':'John'}	# Python is key and GUido is value(lookup table format)

subjects['Python']

# Adding new key value pair
subjects['c'] = 'Richie' #its unordered collctions it may add anyware in the dictionary. It will decided by algorythm. 

#Delete key 
del subjects['c']

# Check in 
'Python' in subjects
True
# converting into List
list(subjects)
['Python', 'Tcl', 'Perl']
#globals() # to get all the bultin functions

subjects = {'Python': 'Guido', 'Perl': 'Larry', 'Tcl':'John'}
type(subjects)
<class 'dict'>

subjects.keys()
dict_keys(['Python', 'Tcl', 'Perl'])

subjects.values()
dict_values(['Guido', 'John', 'Larry'])

subjects.items()
dict_items([('Python', 'Guido'), ('Tcl', 'John'), ('Perl', 'Larry')])# convert into list of tuples.

# Print the value
subjects.get('Python')
or 
subjects['Python']
'Guido'

# Pop out the Tcl from dict
subjects.pop('Tcl')



for i in subjects:
	print('Key =====>', i, 'Value is', subjects[i])

output:
Key =====> Python Value is Guido
Key =====> Perl Value is Larry

	
for key, value in subjects.items():
	print('Key', key, 'Value=', value)
	
	
Key Python Value= Guido
Key Perl Value= Larry

###########
globals().keys() # all inveronment varible which stored in dict
print(env_vars)

# Clear everything in the dict
subjects.clear()





>>> alist1 = ['a', 'b', 'c', 'd']
>>> alist2 = [1,2,3]
>>> list(zip(alist1,alist2))
[('a', 1), ('b', 2), ('c', 3)]
>>> dict(zip(alist1,alist2))
{'c': 3, 'a': 1, 'b': 2}

Task:
string = 'Python programming'

key values
p 2
y 1


for i in sorted(subjects):
	print (i)
#
################################################################
#tuple '()' read only lists

coordinates = (10,20,30)
type(coordinates)
dir(coordinates)
coordinates[0]
coordinates[1:]

#get the index of value
coordinates.index(20)

for i in coordinates:
	print ()
	
atuple = (1,2,3)

atuple + coordinates

atuple * 3 


a, b, c = 10, 20, 30 # another way to create a tuple

a = (10)
type(a)

a = (10,)# comma is mandiate to create a tuple
type(a)

##conver tuple to list
atuple = (1,2,3)
tmp = list(atuple)
tmp

tmp.sort(reverse=True)
tmp

#*differ between sort and sorted

########################################################################
### User Defined Functions:

def function_name ([arguments....]):
	statements
	....
	....
	
why functions:

function_name() # invoke the function


def greet():
	print('Welcome to function')
	

	
def double(x):
	return x ** 2
	
print(double(2))

def double(x,y):
	return x ** y
	
	
def double(x):
	""""This fucntion takes one argument and resturn double of it """
	value = x ** 2
	print(value)
	
double(2)

>>> double.__doc__
'"This fucntion takes one argument and resturn double of it '
>>> dir(double)
['__annotations__', '__call__', '__class__', '__closure__', '__code__', '__defaults__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__get__', '__getattribute__', '__globals__', '__gt__', '__hash__', '__init__', '__kwdefaults__', '__le__', '__lt__', '__module__', '__name__', '__ne__', '__new__', '__qualname__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__']
>>> double.__code__
<code object double at 0x000002604F739930, file "<pyshell#183>", line 1>
>>> 



def times(x,y):
	print('x is', x)
	print('y is', y)
	print (x * Y) # returns None which is if we didn't retunred the value
	return x * y
print(time ("oracle", 3))# polymorphism



# None bool value is False



#Define a function interesect
def intersect(seq1, seq2):
          ''' find the characters which are present in the another string'''
	result =[]
	for x in seq1:
		if x in seq2:
			result.append(x)
			
	return result
	
string1 = "spam"
string2 = "scam"
print(intersect(string1,string2))
#local varibles are - inside the function.
print (result)


#############
myString = 'Python'

def scope(x):
	myString = x
	print('myString contain inside the function', myString)
	
print('myString contain outside the function', myString)

print(scope('Perl'))

#inside mystring was defined from x 

#################

string = 'python'
print('before', string)


def scope():
	global string # global - which makes the varibles
	string = 'Perl programming'
	print('My string is contain inside function', string)

prin(scope())

print('myString contain outside the function', string)

###################


########## Parsing arguments#######################################################################
#by positions- named arguments

def printargs(a,b,c):
	print('Values of a:', a)
	print('Values of b:', b)
	print('Values of c:', c)

print("Positions arguments as follows")	
printargs(1,2,3) # parsing args by position

print("Named argugments as folloes")
printargs(1,c=20,b=22) # parsing args by position


########### Default Arguments;

def printargs(a,b= 'Oracle',c='Pradeep'):# Default argugments should be end only not should be (a=1,b='oracle',c) will not work. a is called as non keyword argument.
	print('Values of a:', a)
	print('Values of b:', b)
	print('Values of c:', c)

print("Positions arguments as follows")	
printargs(1) # parsing args by position

#function connection_server(hostname='default server',port=8080):

# *b will takes all the values as tuple
def printargs(a,*b):
	print('Values of a:', a)
	print('Values of b:', b)
printargs(1,2,3,4)
# remaining arguments as a tuple



######### **b

def printargs(a,**b):
	print('Values of a:', a)
	#print('Values of b:', b)
	print(b)
	for k,v in b.items():
                  print(k,v)
	
printargs(1,val1=10,val2=20)

# keyword argugment is name = 'python'
# non keyword is like python
#*varible - nonkwargs
#**variable - kwargs
	
#####################################################

# rscursive functions
def mysum(L):
	if not L:
		return 0
	else:
		retunr L[0] + mysum(L(1:))

print(mysum([1,2,3,4,5,]))



# recursive functions
def mysum(L):
          print(L)
        if not L:
	  return 0
	else:
	  return L[0] + mysum(L[1:])

print(mysum([1,2,3,4,5]))
#print(mysum([]))

#Factorial
def facto(x):
          if x == 0 or x == 1 :
                    return 1
          else:
                    print("*" * x)
                    return x * facto(x -1)
print(facto(5))





############### LAMBDA ###########
#lambda argugments.....: expression(only singel expression)

g = (lambda x,y: x+y)
>>> g
<function <lambda> at 0x0000029C09E1EC80>
>>> g(10,20)


(lambda x,y: x*y)('Python', 3)
>>> (lambda x,y: x*y)('Python', 3)
'PythonPythonPython'
>>> help()

### MAP#######
def double(x):
	return x +1

map(double,[1,2,3])

list(map(double,[1,2,3]))

################# FILE 

finput = open('char.py')
type(finput)

finput.mode

dir(finput)

finput.read()

finput.read()
#chnage directory
os.chdir('/tmp/ABCD')
finput.tell()

mystring = finput.read()
print(mystring)

##### seek 


# file handling
#open ('filename', 'mode', 'buffering')
#finput.tell() - zero
#finput.seek(0,2) - end of the file offest
#seek(offset[, whence])
finput.tell()
finput.seek(-2,1)

finput.close()
finput.closed()# to check file status open or not by the result True/False.

finput.readline()

# read lines:
finput = open('char.py')
finput.readlines()


############# skip the new lines 

finput = open('char.py')

for i in finput.readlines():
	print(i.strip())
	

for i in finput.readlines():
	print(line, end='')
	
	
line = finput.readline()
line.split()

############## Writing into file:
foutput = open('testing.txt', 'w')

line1 = 'Python programming'
line2 = 'good language\n'

foutput.write(line1)
foutput.write(line2)

#############################################################################################
### Regular Expressions
regex: text matching and extraction. These are case sensitive.
consists of literal char and meta characters.
a-z A-Z 0-9 literal characters.
^ $ . [] * + ? {} () ... Meta characters.
\d \w \s \b \D \W \S \B ..... Meta symbols.

######
import re
['A', 'ASCII', 'DEBUG', 'DOTALL', 'I', 'IGNORECASE', 'L', 'LOCALE', 'M', 'MULTILINE', 'S', 'Scanner', 'T', 'TEMPLATE', 'U', 'UNICODE', 'VERBOSE', 'X', '_MAXCACHE', '__all__', '__builtins__', '__cached__', '__doc__', '__file__', '__loader__', '__name__', '__package__', '__spec__', '__version__', '_alphanum_bytes', '_alphanum_str', '_cache', '_cache_repl', '_compile', '_compile_repl', '_expand', '_locale', '_pattern_type', '_pickle', '_subx', 'compile', 'copyreg', 'error', 'escape', 'findall', 'finditer', 'fullmatch', 'match', 'purge', 'search', 'split', 'sre_compile', 'sre_parse', 'sub', 'subn', 'sys', 'template']
>>> 
re.match# it will only match the keyword at starting only.

myString = 'Python is a good language'

re.match('Python', myString)# match object and string

matchObj = re.match('Python', myString)

matchObj

matchObj.group()
#
matchObj = re.match('good', myString)
matchObj
print(matchObj)

import re

myString = 'Python supports regular exprssions'

matchObj = re.match('Python', myString)

if matchObj:
            print('Found the matched pattern', matchObj.group())
else:
            print('Not found the pattern')



# Search method
Serachs for pattern anywhere

matchObj = re.search('regular', myString)

if matchObj:
            print('Found the matched pattern', matchObj.group())
else:
            print('Not found the pattern')

# Define funtion to find 

def Find(pattern, string):
	matchObj = re.search(pattern, string)
	if matchObj:
		print ('Found the pattern', matchObj.group())
	else:
		pirnt('Not found the pattern')


>>> Find('oracle', 'python in oracle')
Found the pattern oracle

Find('oracle|python', 'python in oracle')
>>> Find('oracle|python', 'python in oracle')
Found the pattern python

Find('^[aeioup]', 'python in oracle')
>>> Find('^[aeioup]', 'python in oracle')
Found the pattern p

Find('[0-9][0-9][0-9]', 'python in oracle 123 3432432 3432434')


Find('^[^pP]', 'python in oracle 123 3432432 3432434') # not starting with pP

Find('^ora[^oO]cle', 'ora1cle and python')

# . charactor could be anything

Find('pyth.n', 'oracle and python')

Find('cle..', 'oracle and python')

>>> Find('pyth.n', 'oracle and python')
Found the pattern python
>>> Find('cle..', 'oracle and python')
Found the pattern cle a

# * charactor zero or more time the preceeding 
Find('pyth*n', 'pythoracle and orace')

.* will match any one charctor and zero or more time till end n.
Find('pty.*n', 'python jdfldjfljdslj1213243n ')

[0-9]*

# ? will check zero or 1 time the preceeding charctor
Find('pyth.*?n', 'pythoracle and orace')

Find('pyth?n', 'python in oracle')

# + 
# diff + match one or more occurances of the preceeding charctor
# where * is zeror or more occurances

Find('pyth+n', 'pythhhhhhnorcle and ptyhnoracle')
>>> Find('pyth+n', 'pythhhhhhnorcle and ptyhnoracle')
Found the pattern pythhhhhhn
#control preceedint occurance to 3 times
Find('pyth{6}n', 'pythhhhhhnorcle and ptyhhhnoracle')
>>> Find('pyth{6}n', 'pythhhhhhnorcle and ptyhhhnoracle')
Found the pattern pythhhhhhn
>>> 


# 
Find('^.{10}$', '1234567890')


\d = [0-9] matches a digit.
Find('\d', 'oracle1234')
>>> Find('\d', 'oracle1234')
Found the pattern 1
>>> Find('\d+', 'oracle1234')# one are more digits check using "+"
Found the pattern 1234

>>> Find('\D+', 'oracle1234')# "D" is for checking not digit. And stops at very firt digit arrives.
Found the pattern oracle
>>> 

###########
\w = [a-z A-Z 0-9_] word charactor

Find('\w+', 'oracle $$$%#%#%#%#%& %@^#^!*&@#*&Y9084298')
>>> Find('\w+', 'oracle $$$%#%#%#%#%& %@^#^!*&@#*&Y9084298')
Found the pattern oracle
>>> 
>>> Find('\w+', 'oracle1234__ $$$%#%#%#%#%& %@^#^!*&@#*&Y9084298')
Found the pattern oracle1234__
>>> 
####
\W = everything other than word characters
>>> Find('\W+', 'oracle1234__ $$$%#%#%#%#%& %@^#^!*&@#*&Y9084298')
Found the pattern  $$$%#%#%#%#%& %@^#^!*&@#*&
>>> 
########
/s = is used for spaces
>>> Find('oracle\spython', 'oracle python')
Found the pattern oracle python
>>> 
>>> Find('oracle\s+python', 'oracle     python    abcd 1234')# one or more spaces using \s+
Found the pattern oracle     python

\S = is other than spaces.


########## 
\b= is used for word boundry
Find(r'\boracle\b', '123oracle python oracel test 123')# r can be used for raw string.
>>> Find(r'\boracle\b', '123oracle python oracle test 123')
Found the pattern oracle


###############
matchObj = re.search('(python)', 'this is python python programming python')
matchObj.groups()



>>> matchObj = re.search('(python)', 'this is python python programming python')
>>> matchObj.groups()
('python',)
>>> matchObj.group()
'python'
>>> matchObj.group(1)
'python'
>>> print(matchObj.groups())
('python',)
>>> 

#### findall
# () capturing the pattern

>>> matchObj = re.findall('(python)', 'this is python python programming python')
>>> matchObj = re.findall('python', 'this is python python programming python')
>>> matchObj
['python', 'python', 'python']


myString = "python is a good language"
>>> matchObj
<_sre.SRE_Match object; span=(0, 6), match='python'>
>>> matchObj = re.search(r'(\w+)', myString)
>>> 
>>> matchObj.groups()
('python',)
>>> matchObj.group(0)
'python'
>>> 


################## Search a mail id#################################
>>> 
>>> email_id = 'sam@oracle.com test_user@gmail.com'
>>> matchObj = re.findall(r'([\w._]+@\w+.\w{3})', email_id)
>>> matchObj
['sam@oracle.com', 'test_user@gmail.com']
>>> tuple(matchObj)
('sam@oracle.com', 'test_user@gmail.com')
>>> 


\w+[._]\w+@\w+[.][A-Za-z]{3}



['test_user@gmail.com']
>>> matchObj = re.findall(r'\w+[._]?\w+@\w+[.][A-Za-z]{3}', email_id)
>>> matchObj
['sam@oracle.com', 'test_user@gmail.com']
>>> 
##################################################################

# re.sub
# is a method to substtute the pattern

string = "python good"
>>> string = "python good"
>>> re.sub('o','O', string)
'pythOn gOOd'
>>>
>>> string = "python good"
>>> re.sub('o','O', string)
'pythOn gOOd'
>>> re.sub('o','O', string,1)# 1 will change one occurance
'pythOn good'
>>> re.sub('o','O', string,2)# 2 occurances
'pythOn gOod'
>>> string		# string wil be same 
'python good'
>>>  
>>> string1 = 'This is contain 1234 oracle'# removeing all the digits
>>> re.sub('\d', '', string1)
'This is contain  oracle'
>>> 

TASK: opean a file for reading (dummy) select all the lines which are having words "orcle" and write those lines into another file called 'matches.txt'

import re
finput = open('dummy.txt', 'r')
fout = open('matches.txt', 'w')
for i in finput.readlines():
            if re.search('oracle', i):
                        fout.write(i)

finput.close()
fout.close()



### compile


import re
re.compile

regex = re.compile('oracle')



############### Exception
#Eception is also a object. It will stop the normal flow of the script.
try except


try:
	code here ...
except exception1:
	print .....
except exception2:
	print ....
else:
	print .....
####################	
try:
            finput = open('C:/Users/pkpasupu/Desktop/scripts/7.py', 'r')
            for line in finput.readline():
                        print(line, end='')

except Exception as k:
            print("exception occurred - {0}".format(k))

else:
            print('Sucessfully read the file')
            finput.close()
	
#####################

# Get the Exception type ###########

try:
    finput=open('inputdat.txt','r')
    for line in finput.readlines():
        print(line)
except Exception as e:
    #print('File not exist'+str(traceback.print_exc(e)))
    print('exception caught is: '+str(type(e).__name__))
else:
    print('reading successful')	

#############



################## Object Oriented concepts:
1. class - blue print which contains/defines attributes and methods.
2. class variable - 
3. Data members - class varibales and instance varibales.
4. fucntion overloading - 
5. instance varibales - the variable which inside the method and it is specific to the instance.
6. Inheritance - derive the class from another class. base class or child clas- parent class
7. Instance - Object
8. method - fucntion defined inside of class def methodname(slef). self is not a keyword it refferes to curent instance.
9. operator overloading - + works numbers, strings, lists and also work on objects.



### Creating a class
>>> class ClassA:
	pass

>>> dir()
['ClassA', '__builtins__', '__doc__', '__file__', '__loader__', '__name__', '__package__', '__spec__']
>>> dir(ClassA)
['__class__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__gt__', '__hash__', '__init__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__']
>>> if 10> 5:
	print('Greater')
else:
	pass

Greater
>>> if 10> 50:
	print('Greater')
else:
	pass

>>> 

class ClassA:
	pass# it reffers to a stub block.
	
objA = ClassA()
>>> objA = ClassA()
>>> dir(objA)
['__class__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__gt__', '__hash__', '__init__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__']
>>> type(objA)
<class '__main__.ClassA'>
>>> objB = ClassA()
>>> id(objA, objB)
Traceback (most recent call last):
  File "<pyshell#179>", line 1, in <module>
    id(objA, objB)
TypeError: id() takes exactly one argument (2 given)
>>> id(objA)
2632675810552
>>> id(objB)
2632675451904
>>> id(objA), id(objB)
(2632675810552, 2632675451904)
>>> del objA
>>> del objB

>>> class Employee:
	def display(self):
		print('Greetings....')

		
>>> objA = Employee()
>>> objB = Employee()
>>> objA.display()
Greetings....
>>> Employee.display(objA)
Greetings....

>>> class Employee:
	def display(self):
		print('Value is', self)
		print('Greetings....')

		
>>> objA = Employee()
>>> objA.display()
Value is <__main__.Employee object at 0x00000264F7ADBDD8>
Greetings....
>>> objB = Employee()
>>> objB.display()
Value is <__main__.Employee object at 0x00000264F7B4DEF0>
Greetings....

>>> class Employee:
	def __init__(self):
		print('Intilasing the values')
	def display(self):
		print('Welcome')

		
>>> 
>>> objA = Employee()
Intilasing the values
>>> objB = Employee()
Intilasing the values
>>> objA.display()
Welcome
>>> objB.display()
Welcome
#################


>>> class Employee:
	def __init__(self,name,place):
		self.name = name
		self.place = place
	def display(self):
		print('Name of the employee', self.name)
		print('Based out in', self.place)
		
		
>>> objA = Employee()# have to provide two argugments
Traceback (most recent call last):
  File "<pyshell#235>", line 1, in <module>
    objA = Employee()
TypeError: __init__() missing 2 required positional arguments: 'name' and 'place'
>>> objA = Employee('Pradeep','Hyderabd')
>>> objB = Employee('Radha','Hyderabd')
>>> print(objA.name)
Pradeep
>>> print(objA.place)
Hyderabd
>>>
>>> objA.display()
Name of the employee Pradeep
Based out in Hyderabd
>>> 

#############################
# Iterators and Generators
>>> alist  = [1,2,3,4,5]
>>> dir(alist)
['__add__', '__class__', '__contains__', '__delattr__', '__delitem__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__getitem__', '__gt__', '__hash__', '__iadd__', '__imul__', '__init__', '__iter__', '__le__', '__len__', '__lt__', '__mul__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__reversed__', '__rmul__', '__setattr__', '__setitem__', '__sizeof__', '__str__', '__subclasshook__', 'append', 'clear', 'copy', 'count', 'extend', 'index', 'insert', 'pop', 'remove', 'reverse', 'sort']
>>> type(alist)
<class 'list'>
>>> itr = iter(alist)
>>> type(itr)
<class 'list_iterator'>
>>> next(itr)
1
>>> next(itr)
2
>>> next(itr)
3
>>> next(itr)
4
>>> next(itr)
5
>>> next(itr)# once the all the elements were completed iteration was stopped.
Traceback (most recent call last):
  File "<pyshell#256>", line 1, in <module>
    next(itr)
StopIteration
>>> 

>>> itr = reversed(alist)
>>> next(itr)
5
>>> next(itr)
4
>>> next(itr)
3
>>> next(itr)
2
>>> next(itr)
1
>>> next(itr)
Traceback (most recent call last):
  File "<pyshell#267>", line 1, in <module>
    next(itr)
StopIteration
>>> 


#Remote control class
class RemoteControl:
            def __init__(self):
                        self.channels = ['CNN', 'NDTV', 'TIMES', 'BBC']
                        self.index = -1# off state

            def __iter__(self):
                        return self

            def __next__(self):
                        self.index = self.index + 1
                        if self.index == len(self.channels):
                                    raise StopIteration
                        return self.channels[self.index]
						
						
						
#Generators: are functions (noraml) but uses yield statement
#

>>> def remote():
	yield "CNN"
	yield "TIMES"
	yield "NDTV"

	
>>> type(remote)
<class 'function'>
>>> 
>>> 
>>> 
>>> itr = remote()
>>> 
>>> type(itr)
<class 'generator'>
>>> 
>>> 
>>> next(itr)
'CNN'
>>> next(itr)
'TIMES'
>>> next(itr)
'NDTV'
>>> next(itr)
Traceback (most recent call last):
  File "<pyshell#332>", line 1, in <module>
    next(itr)
StopIteration
>>> 
####################################################
>>> def gensquar(n):
	for i in list(range(n)):
		yield i ** 2

		
>>> gensquar
<function gensquar at 0x0000025FEE64D510>
>>> itr = gensquar(3)
>>> type(itr)
<class 'generator'>
>>> next(itr)
0
>>> next(itr)
1
>>> next(itr)
4
>>> next(itr)
Traceback (most recent call last):
  File "<pyshell#349>", line 1, in <module>
    next(itr)
StopIteration
>>> 
##################################################
>>> (x for x in range(10))
<generator object <genexpr> at 0x0000025FEE649360>
>>>
>>> x  = (x for x in range(10))
>>> 
>>> for i in x:
	print(i)

	
0
1
2
3
4
5
6
7
8
9
>>> [x for x in range(10)]
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
>>> 



# Inheritance - calling another class methods 

>>> class ClassA:
	def display(self):
		print("Parent class...")

		
>>> 
>>> class ClassB:
	def info(self):
		print("This is another class ClassB")

		
>>> class ClassC(ClassA,ClassB):
	pass

>>> objC = ClassC()
>>> 
>>> objC
<__main__.ClassC object at 0x0000025FEE63DF98>
>>> type(objC)
<class '__main__.ClassC'>
>>> objC.display()
Parent class...
>>> objC.info()
This is another class ClassB
>>> dir(objC)
['__class__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__gt__', '__hash__', '__init__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', '__weakref__', 'display', 'info']
>>> 
####
>>> print('%s had %d experience' %('xyx',100))
xyx had 100 experience
>>> 

############# Inheritance Example:

#Inheitance:
#SchoolMember - Teacher and Stundets
#Name age
#Teachers = salary
#Student = marks
#Base Class School member = Name Age
#Teacher = Salary (inheritae the attributes/methods from the base class)
#Student = marks (inheritae the attributes/methods from the base class)

class SchoolMember:
            '''It is a base class for the Teachers and Studens -- represents members'''

            def __init__(self,name,age):
                        self.Name = name # attributes
                        self.Age = age # attributes
                        print("Initialized the school member", self.Name, self.Age )

            def tell(self):
                        '''Details of the member'''
                        print('Name: %s Age: %d' % (self.Name,self.Age))

class Teacher(SchoolMember):
            '''This defines the attributes for teachers'''
            def __init__(self,name,age,salary):
                        SchoolMember.__init__(self,name,age,)
                        self.Salary = salary
                        print('Initialized the teacher %s' %(self.Salary))

            def tell(self):
                        SchoolMember.tell(self)
                        print('Salary %d' %(self.Salary))

class Student(SchoolMember):
            '''This defines the attributes for Student'''
            def __init__(self,name,age,marks):
                        SchoolMember.__init__(self,name,marks)
                        self.Marks = marks
                        print('Intialized the Student %s' %(self.Marks))

            def tell(self):
                        SchoolMember.tell(self)
                        print('Marks %d' %(self.Marks))

# Create teh instances
t = Teacher('Pradeep', 29, 45000)
s = Student('Radha', 25, 95)

members = [t, s]
for member in members:
            member.tell()
			
			
			
Output:

============ RESTART: C:/Users/pkpasupu/Desktop/scripts/school.py ============
Initialized the school member Pradeep 29
Initialized the teacher 45000
Initialized the school member Radha 95
Intialized the Student 95
Name: Pradeep Age: 29
Salary 45000
Name: Radha Age: 95
Marks 95
>>> 


################## Modules######################

import sys

print('List of arguments passed on the command line')

print('Arguments are:' , sys.argv[1:])

print('Number of arguments are', len(sys.argv))


###### stdout stderr:

>>> sys.stdout
<idlelib.PyShell.PseudoOutputFile object at 0x000001676A7BFBA8>
>>> sys.stdout.write('This goes to terminal')
This goes to terminal21
>>> sys.stderr.write('This goes to terminal')
This goes to terminal21
>>> sys.stdin.write('This goes to terminal ')
Traceback (most recent call last):
  File "<pyshell#400>", line 1, in <module>
    sys.stdin.write('This goes to terminal ')
io.UnsupportedOperation: write
>>> sys.stdout
<idlelib.PyShell.PseudoOutputFile object at 0x000001676A7BFBA8>
>>> saveout = sys.stdout
>>> saveout
<idlelib.PyShell.PseudoOutputFile object at 0x000001676A7BFBA8>
>>> file = open('demo1.py', 'w')
>>> sys.stdout = file
>>> saveout
>>> print('Hello')
>>> saveout
>>> sys.stdout = svaeout
Traceback (most recent call last):
  File "<pyshell#409>", line 1, in <module>
    sys.stdout = svaeout
NameError: name 'svaeout' is not defined
>>> sys.stdout = saveout
>>> print('Hello')
Hello

############ TIME:
>>> import time
>>> time.time()
1498804517.483477
>>> time.localtime(time.time())
time.struct_time(tm_year=2017, tm_mon=6, tm_mday=30, tm_hour=12, tm_min=6, tm_sec=59, tm_wday=4, tm_yday=181, tm_isdst=0)
>>> time.asctime(time.localtime(time.time()))
'Fri Jun 30 12:07:49 2017'
>>> time.ctime(time.time())
'Fri Jun 30 12:07:58 2017'
>>> 
>>> time.strftime('%D',time.localtime(time.time()))
'06/30/17'
>>> time.strftime('%D %T %d-%m-%y',time.localtime(time.time()))
'06/30/17 12:12:06 30-06-17'
>>> time.strftime('%D %T %d-%b-%y',time.localtime(time.time()))
'06/30/17 12:12:44 30-Jun-17'
>>> time.strftime('%d-%b-%y',time.localtime(time.time()))
'30-Jun-17'



############# OS
>>> import os
>>> os.listdir('.')
['demo1.py']
>>> os.getcwd()
'C:\\Users\\pkpasupu\\Desktop\\scripts\\moudles'
>>> os.getenv('PATH')
'C:\\ProgramData\\Oracle\\Java\\javapath;C:\\windows\\system32;C:\\windows;C:\\windows\\System32\\Wbem;C:\\windows\\System32\\WindowsPowerShell\\v1.0\\;C:\\Program Files (x86)\\Sennheiser\\SoftphoneSDK\\;D:\\HashiCorp\\Vagrant\\bin;C:\\Program Files (x86)\\Skype\\Phone\\;C:\\Users\\pkpasupu\\AppData\\Local\\Programs\\Python\\Python35;C:\\Users\\pkpasupu\\AppData\\Local\\atom\\bin'
>>> os.system('dir')#check exit status
0
>>> os.system('dir123')#check exit status
1
>>> 

>>> import os
>>> cmd = 'ls'
>>> fp = os.popen(cmd)
>>> 
>>> fp
<open file 'ls', mode 'r' at 0x7f9d3c4c1d20>
>>> fp.readlines()
['1.py\n', 'python\n']
>>> 


###################################################################################################################
##### Networking Concepts
#scokets: Ip address, Port number. Data structures which ccontains ip address, port address
#- end to end communication.
#- process b/w two process- process on the same machine or different machines.
#IP - Address local address 127.0.0.1
#Ports - 1024 - below reserverd port numbers. ex: 22, 25, 80, 20, 21. We can use upto 65535
#TCP /UDP - Transmition Control protocols/User Datagram protocol. (Acknowledgement)
#UDP - connetion less.


#import socket
# socket(socketfamily, sockettype)
#AF_INET (Address family Inet), AF_PFNET(Address Family platform network)
#socket type default takes as TCP
# socket.SOCK_STREAM - TCP 
# socket.SOCK_DGRAM - UDP
# methods: bind, lisiten, accept (these are required methods)

>>> print(__name__)# called as main name space
__main__
>>> 

def main():
            print('Hello !!!!!')
if __name__ == '__main__':
            main()

##################### SOCKET programme			
import socket

def main():
            hostname = '127.0.0.1'
            port = 5000

            s = socket.socket()
            s.bind((hostname,port))

            s.listen(1) # listening for one connection

            c, addr = s.accept() # accept method returns a tuple connection and address

            print('Connection accpted from', str(addr))

            while True:
                        data = c.recv(1024)# reserving the bufferf size for data 1024
                        if not data:
                                    break
                        print('connected from user' , str(data))
                        data = str(data).upper()
                        print('sending the data', str(data))
                        c.send(data)
            c.close()

if __name__ == '__main__':
            main()
			

#######################################


# Thread and Threading module
#Thread is a low level module, it having less functionalites.
#Threading is  high level module and having more functionalites.

#thread - is a part of process - main thread
#why threads - functions - create a light weight process - to execute these functions.

#threads execute in-parllel.
#once the exection of thereasds are over. it returns to main thread/process.
#join method - main thread will wait for threads to get over. 

#Threds########################

from time import sleep, ctime, time

def loop0():
            print('loop0 started', ctime(time()))
            sleep(5)
            print('loop0 is done ', ctime(time()))

def loop1():
            print('loop1 started', ctime(time()))
            sleep(2)
            print('loop1 is done ', ctime(time()))

def main():
            print('Starting....')
            loop0()
            loop1()
            print('All done....', ctime(time()))

if __name__ == '__main__':
            main()
	

	


			
			







