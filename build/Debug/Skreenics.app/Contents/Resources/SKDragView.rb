# SKDragView.rb
# Skreenics
#
# Created by naixn on 29/04/10.
# Copyright 2010 Thibault Martin-Lagardette. All rights reserved.

require 'csv'

def growl(message, type='')
	system "growlnotify \"D-Bug\" -m\"#{type} #{message}\""
end


class SKDragView < NSView
    attr_writer :dragDelegate

    def initWithCoder(coder)
        if super
            registerForDraggedTypes([NSFilenamesPboardType])
            @acceptableMovieTypes = QTMovie.movieTypesWithOptions(QTIncludeCommonTypes)
			@acceptableBatchTypes = ['public.comma-separated-values-text']
            @dragDelegate = nil
            self
        end
    end

    #pragma mark Drag and Drop Operations

    def draggingEntered(sender)
        # Init some variables
        workspace = NSWorkspace.sharedWorkspace
        filemanager = NSFileManager.defaultManager
        pboard = sender.draggingPasteboard
        sourceDragMask = sender.draggingSourceOperationMask
        canQTKitInitDraggedFiles = false
        pathIsDirectory = false

        # We accept data from pasteboard only if it contains filenames
        if pboard.types.containsObject(NSFilenamesPboardType)
            # Look if we have at least one type of file we can deal with (movie / folder)
            pboard.propertyListForType(NSFilenamesPboardType).each do |filePath|
                ptr = Pointer.new_with_type('B')
                filemanager.fileExistsAtPath(filePath, isDirectory: ptr)
                pathIsDirectory = ptr[0]
                break if pathIsDirectory
                if @acceptableMovieTypes.containsObject(workspace.typeOfFile(filePath, error: nil)) or @acceptableBatchTypes.containsObject(workspace.typeOfFile(filePath, error: nil))
                    canQTKitInitDraggedFiles = true
                    break
                end
            end
            # If a folder is dragged, of the filename list contains a movie, return "NSDragOperationCopy" to get the (+) icon
            if (pathIsDirectory or canQTKitInitDraggedFiles) and (sourceDragMask & NSDragOperationCopy)
                return NSDragOperationCopy
            end
        end
        # If all of the above failed, then we can't handle anything that was dragged
        return NSDragOperationNone
    end

    def performDragOperation(sender)
        pboard = sender.draggingPasteboard
        if pboard.types.containsObject(NSFilenamesPboardType)
            pboard.propertyListForType(NSFilenamesPboardType).each do |filePath|
				
				# if csv batch file
				workspace = NSWorkspace.sharedWorkspace
				if @acceptableBatchTypes.containsObject(workspace.typeOfFile(filePath, error: nil))
					file = File.new(filePath, 'r')

					file.each_line("\n") do |row|
						column = row.split(",")
						
						videos = column[2].split("@")
						
						for video in videos
							shot = video.split(":")
							if not (column[0].nil? or column[0].empty?)
								#growl column[0], "Load"
								@dragDelegate.addDragPathElement(column[0], {:destfolder => column[1],:seq => shot[1], :name => shot[0]})
							end
						end
						
						#break if file.lineno > 10
					end
				# single video file
				else
					@dragDelegate.addDragPathElement(filePath)
				end
            end
            return true
        end
        return false
    end
end

