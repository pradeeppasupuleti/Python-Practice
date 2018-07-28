import xlrd

def asdf(name):
  #print "-------------------{0}-------------------".format(name)
  sheet_1 = book.sheet_by_name(name)
  col = sheet_1.col(10)

#print col[10]

  for i,v in enumerate(col):
    if v.ctype:
      if v.value == "Subnet Details":
        for j in xrange(i, col.__len__()):
          if col[j].ctype:
            print col[j]
            #else:
             # break


book = xlrd.open_workbook("cloud.xlsx")
sheet_name = book.sheet_names()
#print(sheet_name)
#for n,name in enumerate(sheet_name):
for name in sheet_name:
  if name.endswith("BDA"):
    asdf(name)
