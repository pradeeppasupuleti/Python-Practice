import xlrd
import sys
import xlwt
from xlwt import easyxf
from pprint import pprint

def getSubnetIPs(book = "", name = ""):
    xl_sheet = book.sheet_by_name(name)
    req_col_name = "Subnet Details" 
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
        if req_col_name in row_data:
            #print("Found.. in row - {0}".format(row_idx))
            req_column_index = row_data.index(req_col_name)
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
    if sheet.endswith("BDA"):
        sheet_data = getSubnetIPs(book = book, name = sheet)
        #print("Sheet( {0} )  -> {1}".format(sheet, sheet_data))
        all_info += sheet_data

#pprint(all_info)


style1=xlwt.easyxf('font: name Arial, color-index black, bold on, height 200; pattern: pattern solid, fore_colour yellow')
style2=xlwt.easyxf('align: wrap yes')
workbook=xlwt.Workbook(encoding="utf-8")
sheet1=workbook.add_sheet("firewall Sheet")
sheet1.write(0,0, "Source IP", style1)
sheet1.write(0,1, "IP Type", style1)
sheet1.write(0,2, "Protocol", style1)
sheet1.write(0,3, "Destination IP", style1)
sheet1.write(0,4, "Port", style1)
sheet1.write(0,5, "Description", style1)
sheet1.write(1,0, "Internet/Customer", style2)
sheet1.write(1,1, "Internernet source IP", style2)
sheet1.write(1,2, "SSH", style2)
sheet1.write(1,3, "\n".join(all_info), style2)
sheet1.write(1,4, "22", style2)
sheet1.write(1,5, "Customer ssh to bda vm", style2)

workbook.save("Firewall.xls")



