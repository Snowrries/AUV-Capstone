classdef AUV < handle
    % AUV Class

    
    properties
        %Self-Knowledge
        position_x % Row
        position_y % Column
        velocity  %Step size for traversal
        
        %Arrays that track where the AUV has been
        previous_x %for graphing 
        previous_y %for graphing 
        
        %Analysis Variables
        energy % Increments at every traverse call.  Tracks the amount of steps the ROV takes.
        
        %World Knowledge
        border_x  % World Boundary - used for sparse traversal.  
        border_y  % World Boundary - used for sparse traversal
        current_knowledge % Raw Knowledge of the world
        points_of_interest % Queue of points
        pollution_sources % Array that holds pollution sources that we are certain of. Filled after dense traversal.
    end
    
    methods
        %Constructor
        function obj = AUV(x,y,v,bound_x,bound_y)
                if nargin == 0
                    %Default args
                    x = 1;
                    y = 1;
                    v = 1;
                    bound_x = 100;
                    bound_y = 100;
                end
             
                obj.position_x = x;
                obj.position_y = y;
                obj.previous_x = x;
                obj.previous_y = y;
                obj.velocity = v;
                obj.border_x = bound_x;
                obj.border_y = bound_y;
                obj.current_knowledge = zeros(bound_x,bound_y);
                obj.points_of_interest = [];
        end
        
        %Traverses by velocity amount
        %Direction is a string: 'N'(North), 'S'(South), 'E' (East),'W'(West)
        %Flag triggers when an edge is reached
        %N,S traverses rows, E,W traverses Columns.  
        %We are assuming (1,1) is the top left corner of the array
        function flag = traverse(thisAUV, direction)  
            flag = 0;
            switch direction
                case 'S'
                    if(thisAUV.position_x + thisAUV.velocity <= thisAUV.border_x)
                        thisAUV.position_x = thisAUV.position_x + thisAUV.velocity;
                        thisAUV.energy = thisAUV.energy + 1;
                    else
                       flag = 1;
                    end
                case 'N'
                    if(thisAUV.position_x - thisAUV.velocity > 0)
                        thisAUV.position_x = thisAUV.position_x - thisAUV.velocity;
                        thisAUV.energy = thisAUV.energy + 1;
                    else
                        flag = 1;
                    end
                case 'E'
                    if(thisAUV.position_y + thisAUV.velocity <= thisAUV.border_y)
                        thisAUV.position_y = thisAUV.position_y + thisAUV.velocity;
                        thisAUV.energy = thisAUV.energy + 1;
                    else
                        flag = 1;
                    end
                case 'W'
                    if(thisAUV.position_y - thisAUV.velocity > 0)
                        thisAUV.position_y = thisAUV.position_y - thisAUV.velocity;
                        thisAUV.energy = thisAUV.energy + 1;
                    else
                        flag = 1;
                    end
                otherwise
                    warning('Direction must be a string: N,S,W,E')
            end
            thisAUV.previous_x = [thisAUV.previous_x, thisAUV.position_x];
            thisAUV.previous_y = [thisAUV.previous_y, thisAUV.position_y];
            
        end
        
        % Function takes in a direction and flips it.
        function direction = switchDirection(thisAUV,direction)
            switch direction
                case 'S'
                    direction = 'N';
                case 'N'
                    direction = 'S';
                case 'E'
                    direction = 'W';
                case 'W'
                    direction = 'E';
            end
        
        end
        
                % Function takes in a direction and flips it.
        function direction = rotatecw(thisAUV, direction)
            switch direction
                case 'N'
                    direction = 'E';
                case 'E'
                    direction = 'S';
                case 'S'
                    direction = 'W';
                case 'W'
                    direction = 'N';
            end
        end
        
        
        
        %Takes the value at the current position in the world and fills it
        %into current_knowledge.
        %Returns value if valid otherwise 0.
        function value = sample(thisAUV, world)
            value = 0;
            if ((thisAUV.position_x <= thisAUV.border_x) && (thisAUV.position_y <= thisAUV.border_y)) && ((thisAUV.position_x > 0) && (thisAUV.position_y > 0)) 
                thisAUV.current_knowledge(thisAUV.position_x,thisAUV.position_y) = world(thisAUV.position_x,thisAUV.position_y);
                value = world(thisAUV.position_x,thisAUV.position_y);
            end
        end
        
        %Square Traversal
        %step_size is the additional amount it traverses down the longest
        %path in the square. In other words, the 'space' between squares.
        %world - 2d Array of the world
        %target point - this is the interest point from which we wish to
        %begin our traversal.

        function squareTraverse( thisAUV, step_size, end_point, world)
            direction = 'N';
            for n = 1 : end_point
                for i = 1 :  n+step_size
                    thisAUV.sample(world);
                    thisAUV.traverse(direction);
                end
                direction = thisAUV.rotatecw(direction);
                for i = 1 : n+step_size
                    thisAUV.sample(world)
                    thisAUV.traverse(direction)
                end
                direction = thisAUV.rotatecw(direction);
            end
        end
        
        %Point to point traversal
        %thisAUV is the auv in question, with its current location.
        function point_to_point(thisAUV, targetPointx, targetPointy)
            
            if(targetPointx <= thisAUV.border_x && targetPointy <= thisAUV.border_y)
                x = targetPointx - thisAUV.position_x;
                y = targetPointy - thisAUV.position_y;
                absx = abs(x);
                absy = abs(y);
                directionh = 'E';
                directionv = 'S';
                if (targetPointx < thisAUV.position_x)
                    directionh = 'W';
                else 
                    directionh = 'E';
                end
                if (targetPointy < thisAUV.position_y)
                    directionv = 'N';
                else 
                    directionv = 'S';
                end

                while( absx > 0 && absy > 0 )
                    %Travel in a diagonal towards the goal
                    absx = absx - 1;
                    absy = absy - 1;
                    thisAUV.traverse(directionh);
                    thisAUV.traverse(directionv);
                end
                while(absx > 0)
                    thisAUV.traverse(directionh);
                    absx = absx - 1;
                end
                while(absy > 0)
                    thisAUV.traverse(directionv);
                    absy = absy - 1;
                end
            end
        end
        
        
        %sparseTraversal
        %threshold - Value that represents a critical amount of pollution;
        % we should start a dense traversal if we see this
        %World - 2d Array of the world
        %direction_long - the long direction of our lawnmower traversal
        %direction_short - the short side of our lawnmower traversal
        %step_size - the amount it traverses down the short length of the
        % lawnmower traversal.
        function sparseTraverse(thisAUV, step_size,threshold, world, direction_long, direction_short,dense_traverse_params)
            %Goes down the full length of direction_long
            %Traverses direction_short for step_size duration
            
            switch direction_long
                case {'E','W'}
                    long_lim = thisAUV.border_y; 
                    short_lim = thisAUV.border_x; 
                otherwise
                    long_lim = thisAUV.border_x;
                    short_lim = thisAUV.border_y;
            end

            %Need a condition to stop sparseTraverse if high pollution is
            %detected
            for j = 1:step_size:short_lim
                %Long
                for i = 1 : long_lim - 1
                    thisAUV.sample(world);
                    breaktraverse = thisAUV.fill_POI(threshold);
                    %call denseTraverse
                    if breaktraverse == 1
                        max = thisAUV.denseTraverse(world, dense_traverse_params(1),dense_traverse_params(2),dense_traverse_params(3),direction_short ,direction_long);
                        thisAUV.pollution_sources = [thisAUV.pollution_sources,max];
                    end
                    
                    if(thisAUV.traverse(direction_long) == 1)
                        break;
                    end
                    %Point of Interest is a value between 0.3 to 0.7
                    %breaktraverse = 0; If > 0.7 breaktraverse = 1;
                    
                 end
             
                %Go the other way
                direction_long = thisAUV.switchDirection(direction_long);
                %Short
                for x = 1:step_size
                    thisAUV.sample(world);
                    breaktraverse = thisAUV.fill_POI(threshold);
                    %call denseTraverse
                    if breaktraverse == 1
                      max = thisAUV.denseTraverse(world, dense_traverse_params(1),dense_traverse_params(2),dense_traverse_params(3),direction_long,direction_short);
                      thisAUV.pollution_sources = [thisAUV.pollution_sources,max];
                    end
                    if thisAUV.traverse(direction_short) == 1 
                        break;
                    end
                    %Point of Interest is a value between 0.3 to 0.7
                    %breaktraverse = 0; If > 0.7 breaktraverse = 1;
                   
                end
            end
            
           % The last leg of the traversal.  Comment this out and see what
           % happens on the figure; we lose the last row of data.
           % If you have a better solution please feel free this fix this
           for i = 1 : long_lim
                thisAUV.sample(world);
                breaktraverse = thisAUV.fill_POI(threshold);
                if breaktraverse == 1
                    max = thisAUV.denseTraverse(world, dense_traverse_params(1),dense_traverse_params(2),dense_traverse_params(3),direction_short,direction_long);
                    thisAUV.pollution_sources = [thisAUV.pollution_sources,max];
                end
                if thisAUV.traverse(direction_long) == 1 
                   break;
                end
           end
           
           %End of the sparese Traverse.  Start Nearest Neighbour.
           thisAUV.nearestneighbourTraverse(world, dense_traverse_params(1),dense_traverse_params(2),dense_traverse_params(3),direction_long,direction_short);
        end
        
        function nearestneighbourTraverse(thisAUV,world,step_size, distance_long, distance_short, direction_long, direction_short)
            thisAUV.points_of_interest = trim(transpose(thisAUV.points_of_interest),3);
            thisAUV.points_of_interest = transpose(thisAUV.points_of_interest);
            while(isempty(thisAUV.points_of_interest) == 0)
                startpoint = [thisAUV.position_x; thisAUV.position_y];
                columnPOI = nearestneighbour(startpoint,thisAUV.points_of_interest);
                nextpoint = thisAUV.points_of_interest(:,columnPOI);
                thisAUV.points_of_interest(:,columnPOI) = []; %delete so we don't get stuck again
                thisAUV.point_to_point(nextpoint(1),nextpoint(2));
                %Maybe squareTraverse instead
                max = thisAUV.denseTraverse(world,step_size,distance_long,distance_short,direction_long,direction_short);
                thisAUV.pollution_sources = [thisAUV.pollution_sources,max];
            end
        end
        
        %denseTraverse is called whenever the pollution threshold of an
        %area during sparseTraverse exceeds 0.7
        %STEP_SIZE - distance traveled down the short edge of the lawnmower
        %traverse
        %DISTANCE_LONG - the distance of the long edge of the traverse
        %DISTANCE_SHORT - the distance of the short edge of the traverse
        %DIRECTION_LONG - direction faced by the auv during the long edge
        %of the traverse, either North or South
        %DIRECTION_SHORT- direction faced by the auv during the short edge
        %of the traverse, either East or West; usually East
        function max_coor = denseTraverse(thisAUV, world, step_size, distance_long, distance_short, direction_long, direction_short)
         max = realmin;
         max_coor = zeros(2,1);
         for i = 1:distance_long/2
              if max  < thisAUV.sample(world)
                  max = thisAUV.sample(world);
                  max_coor = [thisAUV.position_x;thisAUV.position_y];
              end
              if thisAUV.traverse(direction_long) == 1
                  break;
              end
          end    
          direction_long = thisAUV.switchDirection(direction_long); 
          for k = 1:step_size:distance_short
              %traverse the short end
              for j = 1:step_size
                  if max  < thisAUV.sample(world)
                     max = thisAUV.sample(world);
                     max_coor = [thisAUV.position_x;thisAUV.position_y];
                  end
                  if thisAUV.traverse(direction_short) == 1
                      break;
                  end
              end
              %traverse the long edge              
              for i = 1:distance_long
                if max  < thisAUV.sample(world)
                     max = thisAUV.sample(world);
                     max_coor = [thisAUV.position_x;thisAUV.position_y];
                end
                if thisAUV.traverse(direction_long) == 1
                      break;
                end
              end
              direction_long = thisAUV.switchDirection(direction_long);       
          end
          
          %Travel half the distance_long again in order to position the AUV
          %back on the original path it was traveling
          for m = 1:step_size
              if max  < thisAUV.sample(world)
                     max = thisAUV.sample(world);
                     max_coor = [thisAUV.position_x;thisAUV.position_y];
              end
              if thisAUV.traverse(direction_short) == 1
                 break;
              end
          end
          for l = 1:distance_long/2
              if max  < thisAUV.sample(world)
                     max = thisAUV.sample(world);
                     max_coor = [thisAUV.position_x;thisAUV.position_y];
              end
              if thisAUV.traverse(direction_long) == 1
                  break;
              end
          end
              

          %calculate the gradient
          %calculate_gradient(); 
          
        end    

        function break_traverse = fill_POI(thisAUV,threshold)
            break_traverse = 0;
            if ((thisAUV.position_x <= thisAUV.border_x && thisAUV.position_y <= thisAUV.border_y) && (thisAUV.position_x > 0 && thisAUV.position_y > 0)) 
                       
                        if (threshold(1) < thisAUV.current_knowledge(thisAUV.position_x,thisAUV.position_y) && thisAUV.current_knowledge(thisAUV.position_x,thisAUV.position_y) < threshold(2))
                            thisAUV.points_of_interest = [thisAUV.points_of_interest, [thisAUV.position_x; thisAUV.position_y]];
                            break_traverse = 0; 
                        elseif (thisAUV.current_knowledge(thisAUV.position_x,thisAUV.position_y) >= threshold(2))
                            thisAUV.points_of_interest = [thisAUV.points_of_interest, [thisAUV.position_x; thisAUV.position_y]];
                            disp('Triggered');
                            break_traverse = 1;
                           % disp('Triggered');
                        end 
            end

        end
    end
    
end