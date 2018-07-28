import xlrd
import sys
import xlwt

from pprint import pprint
#from v2 import all_info

def getSubnetIPs(book = "", name = ""):
    xl_sheet = book.sheet_by_name(name)
    req_FE1 = "Subnet Details" 
    req_column_found = False
    req_column_index = 0
    sheet_ips_list = []
    
    num_cols = xl_sheet.ncols   # Number of columns
    for row_idx in range(0, xl_sheet.nrows):    # Iterate through rows
        #print ('Row: %s' % row_idx)
        row_data = []
        for col_idx in range(0, num_cols):  # Iterate through columns
            cell_obj = xl_sheet.cell(row_idx, col_idx)  # Get cell object by row, col
            if cell_obj:
                row_data.append(str(cell_obj.value))
            else:
                row_data.append(str("NA"))
        #print ('Row: [%s] data: [%s]' % (row_idx, ", ".join(row_data)))
        if req_FE1 in row_data:
            #print("Found.. in row - {0}".format(row_idx))
            req_column_index = row_data.index(req_FE1)
            req_column_found = True
            continue
            #process further
        else:
            pass
            #print("Not Found.. in row - {0}".format(row_idx))
            
        if req_column_found and req_column_index:
            if row_data[req_column_index]:
                sheet_ips_list.append(row_data[req_column_index])
                
    return sheet_ips_list

book = xlrd.open_workbook(sys.argv[1])
sheet_name = book.sheet_names()
#print(sheet_name)

# sheet_name = ["c5r504 BDA"]
all_info = []
for sheet in sheet_name:
    if sheet.endswith("Exdata"):
        sheet_data = getSubnetIPs(book = book, name = sheet)
        #print("Sheet( {0} )  -> {1}".format(sheet, sheet_data))
        all_info += sheet_data

FE1=all_info[0]
FE2=all_info[3]
FE3=all_info[6]

print(FE1)
print(FE2)
print(FE3)



