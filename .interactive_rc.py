try:
    import readline
except ImportError:
    print ("Module readline not available.")
else:
    import rlcompleter
    #TODO: Figure out how to make binding to Control-Tab not also grab Tab
    readline.parse_and_bind("tab: complete")
