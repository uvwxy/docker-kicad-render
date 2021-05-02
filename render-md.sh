#!/bin/bash

DEFAULT_DATE=$(date "+%Y-%m-%d")

 if [ "$1" = "--force" ] ;
 then
    echo "FORCING REDRAW"
 fi

cd /opt/render/files/

for PROJECT in $(ls | sort -n); do
    if [ -d $PROJECT ]; then
        cd $PROJECT
        echo "checking $PROJECT ..."
        PCB=$(ls *.kicad_pcb)
        SCH=$(ls *.sch)

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
        if [ "$1" = "--force" ] || [ ! -f "docs/img/$BASENAME-top.svg" ] ;
        then 
            cfg="/opt/render/config.kibot.yaml"
            DIR="-d ./"
            BOARD="-b $PCB"
            SCHEMA="-e $SCH"
            SKIP="--skip-pre run_erc,run_drc" # "-s all"
            kibot -c $cfg $DIR $BOARD $SCHEMA $SKIP
            
            BOARD_TOP="docs/img/$BASENAME-top.svg"
            BOARD_BOT="docs/img/$BASENAME-bottom.svg"
            SCHEMATIC="docs/img/$BASENAME-schematic.svg"
            #convert -density 400 $BASENAME.svg $BASENAME.png
            inkscape -z -d 600 --export-background="#FFFFFF" -D $SCHEMATIC -e docs/img/$BASENAME-schematic.png
            inkscape -z -d 600 --export-background="#FFFFFF" -D $BOARD_TOP -e docs/img/$BASENAME-top.png
            inkscape -z -d 600 --export-background="#FFFFFF" -D $BOARD_BOT -e docs/img/$BASENAME-bottom.png

            convert  docs/img/$BASENAME-schematic.png -thumbnail 256x256^ docs/img/$BASENAME-schematic-sm.jpg
            convert  docs/img/$BASENAME-top.png -thumbnail 256x256^ docs/img/$BASENAME-top-sm.jpg
            convert  docs/img/$BASENAME-bottom.png -thumbnail 256x256^ docs/img/$BASENAME-bottom-sm.jpg

            rm -f fp-info-cache*
            rm -f kicad-$BASENAME.tar.gz
            rm -f gerber-$BASENAME.tar.gz
            if [ -d "gerbers/" ] ;
            then
                tar czf kicad-$BASENAME.tar.gz *.pro *.sch *.net *.kicad_pcb *-cache.lib
                tar czf gerber-$BASENAME.tar.gz gerbers/
            fi

            rm -f kibot_errors.filter
            rm -f config.kibom.ini
            rm -f $BASENAME.xml
        fi
  
        previewFile=docs/img/$BASENAME-top-sm.jpg


        echo "{% include preview-pcb.html \
            title=\"Schematics\" \
            lg=\"/pcbs/$PROJECT/docs/img/$BASENAME-schematic.png\" %}" > $PREVIEWS_FILE
        echo "{% include preview-pcb.html \
            title=\"Front\" \
            lg=\"/pcbs/$PROJECT/docs/img/$BASENAME-top.png\" %}" >> $PREVIEWS_FILE
        echo "{% include preview-pcb.html \
            title=\"Back\" \
            lg=\"/pcbs/$PROJECT/docs/img/$BASENAME-bottom.png\" %}" >> $PREVIEWS_FILE

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
        
        if [ -f "docs/bom/$BASENAME-ibom.html" ] ;
        then
            echo "#### BOM" >> $MD_FILE
            echo "" >> $MD_FILE
            echo "[Click here](/pcbs/$PROJECT/docs/bom/$BASENAME-ibom.html)" >> $MD_FILE
        fi

        if [ -d "gerbers/" ] ;
        then
            echo "#### Gerbers" >> $MD_FILE
            echo "" >> $MD_FILE
            echo "[gerber-$BASENAME.tar.gz ](/pcbs/$PROJECT/gerber-$BASENAME.tar.gz )" >> $MD_FILE
        fi

        cd ..
    fi
done