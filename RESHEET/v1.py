import xlrd
import sys
import xlwt
def subnet(dest_ip):
  sheet_1 = book.sheet_by_name(dest_ip)
  col = sheet_1.col(10)

#print col[10]
  destination_ip = []
  for i,v in enumerate(col):
    if v.ctype:
      if v.value == "Subnet Details":
        for j in xrange(i, col.__len__()):
          if col[j].ctype:
		    destination_ip.append("%s" %(col[j]))
	          				 		   
  #print destination_ip
  return  destination_ip
			
  

"""def date_fill():
  workbook=xlwt.Workbook(encoding="utf-8")
  sheet1=workbook.add_sheet("firewall Sheet")
  
sheet1.write(0,2, subnet(dest_ip))
workbook.save("Firewall.xlsx")
"""

book = xlrd.open_workbook(sys.argv[1])
sheet_name = book.sheet_names()
#print(sheet_name)
destination_ip = []
for dest_ip in sheet_name:
  if dest_ip.endswith("BDA"):
    destination_ip = subnet(dest_ip)
	
	
workbook=xlwt.Workbook(encoding="utf-8")
sheet1=workbook.add_sheet("firewall Sheet")
cell_text = ""
for i in destination_ip:
  cell_text = cell_text + " " + str(i)	

sheet1.write(0,2, cell_text)
workbook.save("Firewall.xls")





