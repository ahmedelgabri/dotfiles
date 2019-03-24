# -*- coding: utf-8 -*-
# pylint: disable=missing-docstring,invalid-name,len-as-condition

import os
import re

# https://github.com/lencioni/dotfiles/blob/eddc37169fd36648791a395a47e2ead3fcadcb87/.vim/pythonx/snippet_helpers.py


def repeat_char(snip, ch):
    comment_char = snip.opt("&commentstring")
    comment_char_len = 0 if comment_char is None else len(comment_char)
    repeated_ch = ch * (int(snip.opt("&tw")) - comment_char_len)

    return (
        comment_char % " " + repeated_ch if not (comment_char is None) else repeated_ch
    )


def pascal_case_basename(basename):
    return "".join(x[0].upper() + x[1:] for x in basename.split("_"))


def dasherize_basename(basename):
    return "-".join(filter(None, _convert_camel_case(basename).split("_")))


# http://stackoverflow.com/a/1176023/18986
def _convert_camel_case(string):
    s1 = re.sub("(.)([A-Z][a-z]+)", r"\1-\2", string)
    return re.sub("([a-z0-9])([A-Z])", r"\1-\2", s1).lower()


def _clean_basename(basename):
    return re.sub("(_spec|-test)$", "", basename or "ModuleName")


def path_to_component_name(path, case_fn):
    """
    If path ends in `index.jsx`, this function will
    return the PascalCased directory name. Otherwise,
    it returns the PascalCased filename. This allows me to use my snippets
    with modules that are like `/path/to/module_name.jsx` and modules that
    are like `/path/to/ModuleName/index.jsx`.
    """
    dirname, filename = os.path.split(path)
    basename = os.path.splitext(filename)[0]
    if basename in ["index"]:
        # Pop the last directory name off the dirname
        return case_fn(_clean_basename(os.path.basename(dirname)))

    return case_fn(_clean_basename(basename))


def complete(text, opts):
    if text:
        opts = [m[len(text) :] for m in opts if m.startswith(text)]
        if len(opts) == 1:
            return opts[0]
    if len(opts) > 0:
        return "(" + "|".join(opts) + ")"
    return ""


def formatTag(argument):
    return " * @param {{}} {0}\n".format(argument)


def jsDoc(tabStop):
    """
    Currently Ultisnips does not support dynamic tabstops, so we cannot add
    tabstops to the datatype for these param tags until that feature is added.
    arguments = tabStop.split(',')\
        if tabStop[0] != '{' else tabStop[1:-1].split(',')
    """
    arguments = tabStop.split(",")
    arguments = [argument.strip() for argument in arguments if argument]

    if len(arguments):
        tags = map(formatTag, arguments)
        doc = "/**\n"
        for tag in tags:
            doc += tag
            doc += " */"
            doc += ""
    else:
        doc = ""

    return doc


def formatVariableName(path):
    path = path.split("/")
    lastPart = path[-1]

    try:
        firstPart = path[-2]
    except IndexError:
        firstPart = ""

    deps_map = {
        "lodash": "_",
        "ramda": "R",
        "react": "* as React",
        "react-dom": "ReactDOM",
        "prop-types": "PropTypes",
        "jquery": "$",
        "classnames": "cn",
    }

    if firstPart == "lodash":
        return lastPart

    if lastPart in deps_map:
        return deps_map[lastPart]

    return re.sub(r"[_\-]", "", lastPart)
