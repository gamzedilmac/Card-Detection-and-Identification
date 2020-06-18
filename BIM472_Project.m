    close all;
    clc;
    
    im = imread('Dataset/green_close.jpg');
    %disp(size(im,1))
    %disp(size(im,2))
    im = imresize(im,1/2,'bilinear');
      
    f_score = 0;
    f_score = 2 * (((68/74)*(68/78)) / ((68/74)+(68/78)))
    
    [rows, columns, ~] = size(im);
    if rows < 3000/2 && columns < 3000/2
        im = imresize(im,3,'bilinear');
    end
    
    %If the picture is horizontal, it makes the picture vertical
    if size(im,1) < size(im,2)
        im = imrotate(im,90);
    end

    updated_img = im;

    spades = imread('Templates\Suits\newMaca2.jpg');
    hearts = imread('Templates\Suits\newKupa2.jpg');
    diamonds = imread('Templates\Suits\newKaro2.jpg');
    clubs = imread('Templates\Suits\newSinek2.jpg');

    rank_A = imread('Templates\Ranks\newA.jpg');
    rank_2 = imread('Templates\Ranks\new2.jpg');
    rank_3 = imread('Templates\Ranks\new3.jpg');
    rank_4 = imread('Templates\Ranks\new4.jpg');
    rank_5 = imread('Templates\Ranks\new5.jpg');
    rank_6 = imread('Templates\Ranks\new6.jpg');
    rank_7 = imread('Templates\Ranks\new7.jpg');
    rank_8 = imread('Templates\Ranks\new8.jpg');
    rank_9 = imread('Templates\Ranks\new9.jpg');
    rank_10 = imread('Templates\Ranks\new10 - Copy.jpg');
    rank_J = imread('Templates\Ranks\newJ.jpg');
    rank_Q = imread('Templates\Ranks\newQ - Copy.jpg');
    rank_K = imread('Templates\Ranks\newK - Copy.jpg');

    number_of_cards = 0;

    shape_names = {'HEARTS','DIAMONDS','SPADES','CLUBS'};
    rank_names = {'A','2','3','4','5','6','7','8','9','10','J','Q','K'};

    suits = {hearts,diamonds,spades,clubs};
    ranks = {rank_A,rank_2,rank_3,rank_4,rank_5,rank_6,rank_7,rank_8,rank_9,rank_10,rank_J,rank_Q,rank_K};

    %Preprocess templates
    for i=1:length(suits)
        suits{i} = preprocess_template(suits{i});
    end

    for i=1:length(ranks)
        ranks{i} = preprocess_template(ranks{i});
    end

    %Preprocess image
    threshold = graythresh(im);
    im = im2bw(im,threshold);
    
    
   imshow(updated_img);
   [separations,n_labels] = bwlabel(im);
   labeledImage = logical(im);
    measurements = regionprops(labeledImage, 'BoundingBox','Orientation');
     for ii = 1:n_labels
                       
            oneregion = (separations==ii);

            %Get the region properties
            polyXY = regionprops(oneregion,'ConvexHull','Area','Centroid','Orientation','BoundingBox');
            
           %If the area is less than 70000, accept it as noise and don't take it
           if (polyXY.Area <=70000)
               continue
           end
 
          %Crop the playing card out
          croppedImage = imcrop(im, polyXY.BoundingBox);
          
          [rows1, columns1, ~] = size(croppedImage);
          if rows1 < 1500/2 && columns1 < 1500/2
                        croppedImage = imresize(croppedImage,2.3,'bilinear');
          end
           
          % Compute orientation angle of the region
          angle = polyXY.Orientation;

          % This handles variation of orientations.
          uprightImage = imrotate(croppedImage, -angle+90);
          [rows, columns] = find(uprightImage);
        
          %Crop the playing card after rotating
          topRow = min(rows);
          bottomRow = max(rows);
          leftColumn = min(columns);
          rightColumn = max(columns);
          croppedImage_og = uprightImage(topRow:bottomRow, leftColumn:rightColumn);
        
          aa = measurements(ii).BoundingBox;
  
          %Get the dimensions of the cropped image
          fprintf('Card detected...\n')
     
          number_of_cards = number_of_cards + 1;
          [r,c] = size(croppedImage_og);

          %Define top left anf bottom right region of playing card
          rotate_angle = {0,180};

          %Define predetermined template sizes to resize the original template.
          size_template = {1,0.7};

          %Variables for max correlation of suit and rank
          max_shape = 0;
          max_rank=0;

          fprintf('Template matching is starting...\n')

          % TEMPLATE MATCHING             

            for i=1:length(rotate_angle)
                croppedImage = imrotate(croppedImage_og,rotate_angle{i});
       
                croppedImage = croppedImage(1:int16(r/2),1:int16(c/2));
                
                %Compute Correlation of suits

                for suits_counter=1:length(suits)
                    for q=1:length(size_template)
                        current_shape = imresize(suits{suits_counter},size_template{q});
                        shape_correlation_matrix = normxcorr2(current_shape,croppedImage);
                        shape_correlation = max(shape_correlation_matrix(:));

                         if shape_correlation > 0.9
                            shape = shape_names{suits_counter};
                            max_shape = shape_correlation;
                            break;
                         end
                    if (shape_correlation > max_shape)
                        max_shape = shape_correlation;
                        shape = shape_names{suits_counter};
                    end
                  end
                end

            %Compute Correlation of ranks 

            for ranks_counter=1:length(ranks)

                for q=1:length(size_template)

                    current_rank = imresize(ranks{ranks_counter},size_template{q});
                    rank_correlation_matrix = normxcorr2(current_rank,croppedImage);
                    rank_correlation = max(rank_correlation_matrix(:));
                    if rank_correlation > 0.9
                        max_rank =  rank_correlation;
                        rank = rank_names{ranks_counter};
                        break;
                    end
                    if (rank_correlation > max_rank)
                        max_rank = rank_correlation;
                        rank = rank_names{ranks_counter};
                    end
                        
                end
                
            end
           
            end

            fprintf('Card identification is complete...\n\n')

            %Get rank and shape
            output_of_card = sprintf('%s of %s', rank,shape);
            
            position = [polyXY.Centroid(1) polyXY.Centroid(2)];
            
            %Frame the detected object
            updated_img=rectangle('Position',[aa(1),aa(2),aa(3),aa(4)],'EdgeColor','r','LineWidth',3); 
            %Change the font and size of the output
       text(polyXY.Centroid(1),polyXY.Centroid(2),output_of_card, 'Color', 'y','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',12,'fontweight','bold');

 
     end
       
     text_format = sprintf('Number of cards detected=%d\n',number_of_cards);
     fprintf(text_format);


function template=preprocess_template(im)
    template = 0;
    im = imresize(im,1/2,'bilinear');
    threshold = graythresh(im);
    im = im2bw(im,threshold);
    template = im;
end