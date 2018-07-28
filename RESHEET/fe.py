def getSubnetIPs(book = "", name = ""):
    xl_sheet = book.sheet_by_name(name)
    req_FE1 = "INTERFACE CATEGORY" 
    req_column_found = False
    req_column_index = 0
    sheet_ips_list = []
    
    num_cols = xl_sheet.ncols
    for row_idx in range(0, xl_sheet.nrows):         
        row_data = []
        for col_idx in range(0, num_cols):  
            cell_obj = xl_sheet.cell(row_idx, col_idx)  
            if cell_obj:
                row_data.append(str(cell_obj.value))
            else:
                row_data.append(str("NA"))
        
        if req_FE1 in row_data:
            print("Found.. in row - {0}".format(row_idx))
            req_column_index = row_data.index(req_FE1)
            req_column_found = True
            continue           
        else:
            pass
            
            
        if req_column_found and req_column_index:
            if row_data[req_column_index]:
                sheet_ips_list.append(row_data[req_column_index])
                
    return sheet_ips_list
