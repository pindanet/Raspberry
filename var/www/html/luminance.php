<?php 
    # Function to determine the average luminance of an image
    function image_avg_luminance($filename, $num_samples=10, $section="all")
    {
        # Variables required
        $img        = imagecreatefromjpeg($filename);
        $width      = imagesx($img);
        $height     = imagesy($img);
        $x_step     = intval($width/$num_samples);
        $y_step     = intval($height/$num_samples);
        $x_start    = 0;
        $y_start    = 0;
        $total_lum  = 0;
        $sample_no  = 1;
        $section    = strtolower(trim($section));
        # We need to be able to section the image out.
        switch($section)
        {
            # We need to be able to section the top of the image alone
            case "top":
                $height     = ceil($height / 2);
                break;
            # We also need to be able to section the bottom
            case "bottom":
                $y_start    = ceil($height / 2);
                break;
            # We need to be able to section the top of the image alone
            case "left":
                $width      = ceil($width / 2);
                break;
            # We also need to be able to section the bottom
            case "right":
                $y_start    = ceil($width / 2);
                break;
            # If there is not section, or it's all sections we will not alter the width or height
            case "all":
            default:
                break;
        }
        # Loop through the x axis
        for ($x=$x_start; $x<$width; $x+=$x_step)
        {
            # Loop through the y axis
            for ($y=$y_start; $y<$height; $y+=$y_step)
            {
                $rgb    = imagecolorat($img, $x, $y);
                $r      = ($rgb >> 16) & 0xFF;
                $g      = ($rgb >> 8) & 0xFF;
                $b      = $rgb & 0xFF;
                # Luminance formula
                // http://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color
                $lum    = ($r+$r+$b+$g+$g+$g)/6;
                $total_lum += $lum;
                # Debugging
                // echo "$sample_no - XY: $x,$y = $r, $g, $b = $lum<br />";
                $sample_no++;
            }
        }
        # Determine the average
        $avg_lum  = ceil($total_lum / $sample_no);
        return $avg_lum;
    }
    echo image_avg_luminance("motion/luminance.jpg");
?>
