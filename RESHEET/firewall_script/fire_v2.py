import xlrd
import sys
import xlwt
from xlwt import easyxf
from pprint import pprint

def getSubnetIPs(book = "", name = ""):
    xl_sheet = book.sheet_by_name(name)
    req_col_name_01 = "INTERFACE CATEGORY"
    req_col_name_02 = "Subnet Details"
    req_columns_found = False
    req_column_index_01 = 0
    req_column_index_02 = 0
    sheet_ips_list = []
    
    num_cols = xl_sheet.ncols   # Number of columns
    for row_idx in range(0, xl_sheet.nrows):    # Iterate through rows
        #print ('Row: %s' % row_idx)
        row_data = []
        for col_idx in range(0, num_cols):  # Iterate through columns
            cell_obj = xl_sheet.cell(row_idx, col_idx)  # Get cell object by row, col
#             pprint(cell_obj)
            if cell_obj:
                row_data.append(str(cell_obj.value))
#                 pprint(row_data)
            else:
                row_data.append(str("NA"))
        #print ('Row: [%s] data: [%s]' % (row_idx, ", ".join(row_data)))
        if (req_col_name_01 in row_data) and (req_col_name_02 in row_data):
            #print("Found.. in row - {0}".format(row_idx))
            req_column_index_01 = row_data.index(req_col_name_01)
            req_column_index_02 = row_data.index(req_col_name_02)
            req_columns_found = True
            continue
            #process further
        else:
            pass
            #print("Not Found.. in row - {0}".format(row_idx))
            
        if req_columns_found and req_column_index_01 and req_column_index_02:
            if row_data[req_column_index_02] and row_data[req_column_index_01]:
                if row_data[req_column_index_01].lower().startswith('customer'):
                    sheet_ips_list.append(row_data[req_column_index_02])
                
    return sheet_ips_list

    
    
def get_fe_be_mgmt_IPs(book = "", name = ""):
    xl_sheet = book.sheet_by_name(name)
    req_col_name_01 = "INTERFACE CATEGORY"
    req_col_name_02 = "Subnet Details"
    req_columns_found = False
    req_column_index_01 = 0
    req_column_index_02 = 0
    fe_ips_list = []
    be_ips_list = []
    mgmt_ips_list = []
    bdcs_mgmt_ip = []
    
    num_cols = xl_sheet.ncols   # Number of columns
    for row_idx in range(0, xl_sheet.nrows):    # Iterate through rows
        #print ('Row: %s' % row_idx)
        row_data = []
        for col_idx in range(0, num_cols):  # Iterate through columns
            cell_obj = xl_sheet.cell(row_idx, col_idx)  # Get cell object by row, col
#             pprint(cell_obj)
            if cell_obj:
                row_data.append(str(cell_obj.value))
#                 pprint(row_data)
            else:
                row_data.append(str("NA"))
        #print ('Row: [%s] data: [%s]' % (row_idx, ", ".join(row_data)))
        if (req_col_name_01 in row_data) and (req_col_name_02 in row_data):
            #print("Found.. in row - {0}".format(row_idx))
            req_column_index_01 = row_data.index(req_col_name_01)
            req_column_index_02 = row_data.index(req_col_name_02)
            req_columns_found = True
            continue
            #process further
        else:
            pass
            #print("Not Found.. in row - {0}".format(row_idx))
            
        if req_columns_found and req_column_index_01 and req_column_index_02:
            if row_data[req_column_index_02] and row_data[req_column_index_01]:
                if row_data[req_column_index_01].lower().startswith('customer') and row_data[req_column_index_01].lower().endswith('fe'):
                    fe_ips_list.append(row_data[req_column_index_02])
                elif row_data[req_column_index_01].lower().startswith('customer') and row_data[req_column_index_01].lower().endswith('be'):
                    be_ips_list.append(row_data[req_column_index_02])
                elif row_data[req_column_index_01].lower().startswith('customer') and row_data[req_column_index_01].lower().endswith('mgmt'):
                    mgmt_ips_list.append(row_data[req_column_index_02])
                elif row_data[req_column_index_01] == "BDCS Management":
                    bdcs_mgmt_ip.append(row_data[req_column_index_02])
                   
                
    return fe_ips_list, be_ips_list, mgmt_ips_list, bdcs_mgmt_ip
    
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
    else:
        print("There is no sheets with the suffix BDA")

fe_info = []
be_info = []
mgmt_info = []
bdcs_mgmt_info = []
for sheet in sheet_name:
    if sheet.lower().endswith("exdata"):
        #sheet_data = getSubnetIPs(book = book, name = sheet)
        #print(sheet)
        fe_data, be_data, mgmt_data, bdcs_mgmt = get_fe_be_mgmt_IPs(book = book, name = sheet)
        fe_info += fe_data
        be_info += be_data
        mgmt_info += mgmt_data
        bdcs_mgmt_info += bdcs_mgmt
    else:
        print("There is no sheets with the suffix exdata")    
        
EM_SM = ["nlcl423ru05.nldc1.oraclecloud.com","nlcl423ru06.nldc1.oraclecloud.com","nlcl423ru07.nldc1.oraclecloud.com","nlcl423ru11.nldc1.oraclecloud.com"]
US_SM = ["chr302ru27.usdc2.oraclecloud.com","chr302ru26.usdc2.oraclecloud.com","chr302ru25.usdc2.oraclecloud.com","chr302ru22.usdc2.oraclecloud.com"]


if all_info and bdcs_mgmt_info and mgmt_info and be_info and fe_info:
    style1=xlwt.easyxf('font: name Calibri, color-index black, bold on, height 280; pattern: pattern solid, fore_colour yellow')
    style2=xlwt.easyxf('align: wrap yes; font: name Calibri, height 220')
    workbook=xlwt.Workbook(encoding="utf-8")
    sheet1=workbook.add_sheet("firewall Sheet")
    sheet1.col(0).width = 8000
    sheet1.col(1).width = 7000
    sheet1.col(2).width = 3000
    sheet1.col(3).width = 7000
    sheet1.col(4).width = 7000
    sheet1.col(5).width = 9000
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
    sheet1.write(2,0, "Internet/Customer", style2)
    sheet1.write(2,1, "Internernet source IP", style2)
    sheet1.write(2,2, "SSH", style2)
    sheet1.write(2,3, "\n".join(fe_info), style2)
    sheet1.write(2,4, "22", style2)
    sheet1.write(2,5, "customer ssh access to Exadata VMs (client Interface)", style2)
    sheet1.write(3,0, "Internet/Customer", style2)
    sheet1.write(3,1, "Internernet source IP", style2)
    sheet1.write(3,2, "SSH", style2)
    sheet1.write(3,3, "\n".join(be_info), style2)
    sheet1.write(3,4, "22", style2)
    sheet1.write(3,5, "customer ssh access to Exadata VM (backup Interface)", style2)
    sheet1.write(4,0, "Internet/Customer", style2)
    sheet1.write(4,1, "Internernet source IP", style2)
    sheet1.write(4,2, "SSH", style2)
    sheet1.write(4,3, "\n".join(mgmt_info), style2)
    sheet1.write(4,4, "22", style2)
    sheet1.write(4,5, "customer ssh access to Exadata VM (mgmt Interface)", style2)
    sheet1.write(5,0, "Internet/Customer", style2)
    sheet1.write(5,1, "Internernet source IP", style2)
    sheet1.write(5,2, "HTTPS", style2)
    sheet1.write(5,3, "\n".join(all_info), style2)
    sheet1.write(5,4, "7183", style2)
    sheet1.write(5,5, "Customer access to Cloudera Manager UI Inside BDA Vms", style2)
    sheet1.write(6,0, "Internet/Customer", style2)
    sheet1.write(6,1, "Internernet source IP", style2)
    sheet1.write(6,2, "HTTPS", style2)
    sheet1.write(6,3, "\n".join(all_info), style2)
    sheet1.write(6,4, "8888", style2)
    sheet1.write(6,5, "customer access to Hue UI inside BDA VMs", style2)
    sheet1.write(7,0, "\n".join(all_info), style2)
    sheet1.write(7,1, "---", style2)
    sheet1.write(7,2, "---", style2)
    sheet1.write(7,3, "ALL", style2)
    sheet1.write(7,4, "ALL", style2)
    sheet1.write(7,5, "Unlimted access from Customer VM to Internet", style2)
    sheet1.write(8,0, "\n".join(EM_SM), style2)
    sheet1.write(8,1, "---", style2)
    sheet1.write(8,2, "SSH", style2)
    sheet1.write(8,3, "\n".join(all_info), style2)
    sheet1.write(8,4, "22", style2)
    sheet1.write(8,5, "SM ssh access to bdcs mgmt network", style2)
    sheet1.write(9,0, "\n".join(EM_SM), style2)
    sheet1.write(9,1, "---", style2)
    sheet1.write(9,2, "SSH", style2)
    sheet1.write(9,3, "\n".join(fe_info), style2)
    sheet1.write(9,4, "22", style2)
    sheet1.write(9,5, "SM MT1/MT2 ssh access to Exadata Customer VM", style2)
    
    workbook.save("Firewall.xls")
    print("Fire wall sheet Generated Successfully...")

else:
    print("Unable to get all the information to generate Fire wall sheet...")

