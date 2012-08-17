#!/bin/sh

#  CompilePNG.sh
#  Store
#
#  Created by Tennyson Hinds on 8/14/12.
#  Copyright (c) 2012 __MyCompanyName__. All rights reserved.

#Arguments in Build Target Settings
#ARG0 = Image Resources Folder -- Where all of the image files are held
#ARG1 = Template Folder -- Where the Template .h and .m files are stored

# Where the images are (get this from the first "Input Files" entry)
IMAGE_RESOURCES_FOLDER=`dirname "$SCRIPT_INPUT_FILE_0"`

# Where the template files are located
TEMPLATE_FOLDER=`dirname "$SCRIPT_INPUT_FILE_1"`


# The name of the source template, minus extension
SOURCE_NAME="TPCompiledResources"

# Create C arrays, representing each image
tmp="$TEMP_FILES_DIR/compile-images-$$.tmp"
cd "$IMAGE_RESOURCES_FOLDER"
for image in *.png; do
xxd -i "$image" >> $tmp.1
done


# Read the code template
TEMPLATE=`sed -n '/{%LOAD_TEMPLATE%}/,/{%LOAD_TEMPLATE END%}/ p' "$TEMPLATE_FOLDER/$SOURCE_NAME.m" | sed '1 d;$ d'`

# Create loader code for each image
for image in *.png; do
if echo "$image" | grep -q "@2x"; then continue; fi
ORIGINAL_FILENAME="$image"
SANITISED_FILENAME=`echo "$ORIGINAL_FILENAME" | sed 's/[^a-zA-Z0-9]/_/g'`
SANITISED_2X_FILENAME=`echo "$SANITISED_FILENAME" | sed 's/_png/_2x_png/'`
echo "$TEMPLATE" | sed "s/ORIGINAL_FILENAME/$ORIGINAL_FILENAME/g;s/SANITISED_FILENAME/$SANITISED_FILENAME/g;s/SANITISED_2X_FILENAME/$SANITISED_2X_FILENAME/g" >> $tmp.2
done

# Create the source file from the template and our generated code
sed "/{%IMAGEDATA START%}/ r $tmp.1
1,/{%IMAGEDATA START%}/!{/{%IMAGEDATA END%}/,/{%IMAGEDATA START%}/! d;}
/{%IMAGELOADERS START%}/ r $tmp.2
1,/{%IMAGELOADERS START%}/!{/{%IMAGELOADERS END%}/,/{%IMAGELOADERS START%]/! d;}" "$TEMPLATE_FOLDER/$SOURCE_NAME.m" > "$DERIVED_FILE_DIR/$SOURCE_NAME.m"

# Copy the template header file in
cp "$TEMPLATE_FOLDER/$SOURCE_NAME.h" "$DERIVED_FILE_DIR/$SOURCE_NAME.h"

rm "$tmp.1" "$tmp.2"