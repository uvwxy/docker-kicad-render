#!/bin/bash

DEFAULT_DATE=$(date "+%Y-%m-%d")

cd /opt/render/files/

for PROJECT in $(ls | sort -n); do
    if [ -d $PROJECT ]; then
        cd $PROJECT
        echo "checking $PROJECT ..."
        PCB=$(ls *.kicad_pcb)

        DATE_FILE="pcb.date"
        if [ ! -f $DATE_FILE ];
        then
            echo $DEFAULT_DATE > $DATE_FILE
        fi
        MD_FILE="$(cat pcb.date)-$PROJECT.md"
        TITLE_FILE="pcb.title"
        DESCR_FILE="pcb.descr"
        DESCRIPTION_FILE="pcb.description"
        PREVIEWS_FILE="pcb.previews"
        PREVIEW_FILE="pcb.preview"

        BASENAME=$(basename $PCB .kicad_pcb)
        if [ ! -f $BASENAME.svg ] ;
        then 
            pcbdraw --silent --style ../../style.json $PCB $BASENAME.svg
            pcbdraw --silent --style ../../style.json -b $PCB $BASENAME-back.svg

            # convert -density 400 $BASENAME.svg $BASENAME.png
            inkscape -z -d 400 -D $BASENAME.svg -e $BASENAME.png
            inkscape -z -d 400 -D $BASENAME-back.svg -e $BASENAME-back.png

            convert  $BASENAME.png -thumbnail 256x256^ $BASENAME-sm.jpg
        fi
        tar czf kicad-$BASENAME.tar.gz *.pro *.sch *.net *.kicad_pcb *-cache.lib

        previewFile=$BASENAME-sm.jpg

        echo "{% include preview-pcb.html \
            title=\"Front\" \
            lg=\"/pcbs/$PROJECT/$BASENAME.png\" %}" > $PREVIEWS_FILE
        echo "{% include preview-pcb.html \
            title=\"Back\" \
            lg=\"/pcbs/$PROJECT/$BASENAME-back.png\" %}" >> $PREVIEWS_FILE

        # create defaults

        if [ ! -f $TITLE_FILE ];
        then
            echo "$PROJECT" > $TITLE_FILE
        fi

        if [ ! -f $DESCR_FILE ];
        then
            echo "Yet another PCB." > $DESCR_FILE
        fi

        if [ ! -f $DESCRIPTION_FILE ];
        then
            echo "This PCB has no description." > $DESCRIPTION_FILE
        fi

        if [ ! -f $PREVIEW_FILE ];
        then
            echo "$previewFile" > $PREVIEW_FILE
        fi

         echo "---" > $MD_FILE
        echo "category: pcb" >> $MD_FILE
        echo "title: $(tail $TITLE_FILE)" >> $MD_FILE
        echo "layout: post" >> $MD_FILE
        echo "description: $(tail $DESCR_FILE)" >> $MD_FILE
        echo "previewPath: /pcbs/$PROJECT/$(tail $PREVIEW_FILE)" >> $MD_FILE
        echo "---" >> $MD_FILE
        cat $DESCR_FILE >> $MD_FILE
        echo "" >> $MD_FILE
        echo "#### PCB" >> $MD_FILE
        cat $PREVIEWS_FILE >> $MD_FILE
        echo "" >> $MD_FILE
        echo "#### Description" >> $MD_FILE
        echo "" >> $MD_FILE
        cat $DESCRIPTION_FILE >> $MD_FILE
        echo "#### Source files" >> $MD_FILE
        echo "[kicad-$BASENAME.tar.gz](/pcbs/$PROJECT/kicad-$BASENAME.tar.gz)" >> $MD_FILE
        echo "<br/><br/><small>You can edit this with KiCad. You can get it here: [https://www.kicad-pcb.org/](https://www.kicad-pcb.org/)</small>" >> $MD_FILE
        echo "" >> $MD_FILE

        cd ..
    fi
done