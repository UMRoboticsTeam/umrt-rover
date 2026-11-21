import cantools.database
import sys
import os

def translate(source_path: str, dbc_export_path: str):
    db = cantools.database.load_file(source_path)
    cantools.database.dump_file(db, dbc_export_path)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise RuntimeError(f"Script must be called with a path to a cantools-supported file, and a path to export the "
                           f"DBC file to. Received: {sys.argv}")
    source_path = sys.argv[1]
    dbc_export_path = sys.argv[2]
    
    if not dbc_export_path.endswith('.dbc'):
        raise RuntimeError(f"DBC file to export to must end in \".dbc\". Received: {dbc_export_path}")
    
    print("Ensuring output folder exists")
    os.makedirs(os.path.dirname(dbc_export_path), exist_ok=True)
    
    translate(source_path, dbc_export_path)
    