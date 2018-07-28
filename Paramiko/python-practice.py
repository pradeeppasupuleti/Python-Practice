1. Define a function max() that takes two numbers as arguments and returns the largest of them. Use the if-then-else
construct available in Python. (It is true that Python has the max() function built in, but writing it yourself is
nevertheless a good exercise.)

ANS):
def myfun_max(a,b):
	if a > b:
		return a
	else:
		return b

2. Define a function max_of_three() that takes three numbers as arguments and returns the largest of them.

ANS):
def myfun_max(a,b,c):
	if a > b and a > c:
		return a
	elif b > a and b > c:
		return b
	else:
		return c
		
3. Define a function that computes the length of a given list or string. (It is true that Python has the len() function built
in, but writing it yourself is nevertheless a good exercise.)

ANS):		
s = "Pradeep"
>>> count_len(s)
>>> def count_len(s):
	count = 0
	for _ in s:
		count += 1
	return count

>>> count_len(s)
7
>>> len(s)
7

4. Write a function that takes a character (i.e. a string of length 1) and returns True if it is a vowel, False otherwise.
>>> def vowel(c):
	return c.lower() in "aeiou"

	ANS):
>>> vowel("k")
False
>>> vowel("a")
True
>>> 

5. Write a function translate() that will translate a text into "rövarspråket" (Swedish for "robber's language"). That is,
double every consonant and place an occurrence of "o" in between. For example, translate("this is fun") should return
the string "tothohisos isos fofunon".



6. Define a function sum() and a function multiply() that sums and multiplies (respectively) all the numbers in a list of
numbers. For example, sum([1, 2, 3, 4]) should return 10, and multiply([1, 2, 3, 4]) should return 24.

ANS):

