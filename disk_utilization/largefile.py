import os, time

objects = os.listdir(".")

sofar = 0
name = ""

for item in objects:
        size = os.path.getsize(item)
        if size > sofar:
                sofar = size
                name = item

print "Largest file is "+name+ " at "+\
        str(sofar) + " bytes"

changed = os.path.getmtime(name)
reform = time.ctime(changed)

print "It was last modified at "+str(changed)+\
        " i.e. "+reform
