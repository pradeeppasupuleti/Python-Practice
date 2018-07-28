from os.path import join, dirname, abspath
import xlrd
import sys
from pprint import pprint

"""
fname = sys.argv[1]
sheet_name = sys.argv[2]

xl_workbook = xlrd.open_workbook(fname)
sheet_names = xl_workbook.sheet_names()
print('Sheet Names', sheet_names)

xl_sheet = xl_workbook.sheet_by_name(sheet_names[0])

#  (sheets are zero-indexed)
#
xl_sheet = xl_workbook.sheet_by_index(0)
print ('Sheet name: %s' % xl_sheet.name)

# Pull the first row by index
#  (rows/columns are also zero-indexed)
#
row = xl_sheet.row(0)  # 1st row

# Print 1st row values and types
#
from xlrd.sheet import ctype_text   

print('(Column #) type:value')
for idx, cell_obj in enumerate(row):
    cell_type_str = ctype_text.get(cell_obj.ctype, 'unknown type')
    print('(%s) %s %s' % (idx, cell_type_str, cell_obj.value))

# Print all values, iterating through rows and columns
#
num_cols = xl_sheet.ncols   # Number of columns
for row_idx in range(0, xl_sheet.nrows):    # Iterate through rows
    print ('-'*40)
    print ('Row: %s' % row_idx)   # Print row number
    for col_idx in range(0, num_cols):  # Iterate through columns
        cell_obj = xl_sheet.cell(row_idx, col_idx)  # Get cell object by row, col
        print ('Column: [%s] cell_obj: [%s]' % (col_idx, cell_obj))
"""

if __name__ == "__main__":
    # python parse_xlsx.py <xlsx file> <sheet name>
    if len(sys.argv) != 3:
	if len(sys.argv) == 2:
            xl_workbook = xlrd.open_workbook(sys.argv[1])
            sheet_names = xl_workbook.sheet_names()
            pprint('Sheet Names:')
            pprint(sheet_names)
            pprint('Execution format -> # python parse_xlsx.py <xlsx file> <sheet name>')
        else:
            print("Execution format -> # python parse_xlsx.py <xlsx file> <sheet name>")
    else:
        print "actual execution stats here!!!"
	
