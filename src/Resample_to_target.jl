include("./MedImage_data_struct.jl")
include("./Load_and_save.jl")
include("./Spatial_metadata_change.jl")
using Interpolations

"""
overwriting this function from Interpolations.jl becouse check_ranges giving error

"""
function scale(itp::AbstractInterpolation{T,N,IT}, ranges::Vararg{AbstractRange,N}) where {T,N,IT}
    # overwriting this function becouse check_ranges giving error
    # check_ranges(itpflag(itp), axes(itp), ranges)
    ScaledInterpolation{T,N,typeof(itp),IT,typeof(ranges)}(itp, ranges)
end


"""
given two MedImage objects and a Interpolator enum value return the moving MedImage object resampled to the fixed MedImage object
images should have the same orientation origin and spacing; their pixel arrays should have the same shape
It require multiple steps some idea of implementation is below
1) check origin of both images as for example in case origin of the moving image is not in the fixed image we need to return zeros
2) we should define a grid on the basis of locations of the voxels in the fixed image and interpolate voxels from the moving image to the grid using for example GridInterpolations

   """
   function resample_to_image(im_fixed::MedImage, im_moving::MedImage, interpolator_enum::Interpolator_enum)::MedImage

    # get direction from one and set it to other
    im_moving=change_orientation(im_moving,number_to_enum_orientation_dict[im_fixed.direction])

    # Calculate the transformation from moving image space to fixed image space
    old_spacing = im_moving.spacing
    new_spacing=im_fixed.spacing
    new_size = size(im_fixed.voxel_data)
    points_to_interpolate = get_base_indicies_arr(new_size)

    points_to_interpolate=points_to_interpolate.-1
    points_to_interpolate=points_to_interpolate.*new_spacing
    points_to_interpolate=points_to_interpolate.+1

    #adding diffrence in origin we act as if moving image has origin 0.0,0.0,0.0 - needed for interpolation
    origin_diff=(collect(im_fixed.origin)-collect(im_moving.origin))
    points_to_interpolate=points_to_interpolate.+origin_diff

    #now we need to filter out all points that are outside of the fixed image
    #so by convention that origin is at 0,0,0 we need to filter out all points that are negative plus all 
    #points that are bigger than the size of the fixed image
    
    
    # new_size_physical = (new_size .* new_spacing)+origin_diff
    # points_to_interpolate=points_to_interpolate[findall(x->x[1]>=0 && x[2]>=0 && x[3]>=0 && x[1]<=new_size_physical[1] && x[2]<=new_size_physical[2] && x[3]<=new_size_physical[3],points_to_interpolate)]
    # if(size(points_to_interpolate)[0]==0)
    #     return update_voxel_and_spatial_data(im, zeros(new_size) ,im_fixed.origin,new_spacing,im_fixed.direction)
    # else




    #now issue is that could have points outside of the new new_size_physical; and or new_size_physical can be bigger then old_image
    #hence we need to establish in new space how big is the are we had points on - so the size of transformed image
    #then we need to reshape it to this size
    #then we need to pad to the desired size (size of fixed image)

    # Get the values at the corners
    corners = [
        im_fixed.voxel_data[1, 1, 1],
        im_fixed.voxel_data[1, 1, end],
        im_fixed.voxel_data[1, end, 1],
        im_fixed.voxel_data[1, end, end],
        im_fixed.voxel_data[end, 1, 1],
        im_fixed.voxel_data[end, 1, end],
        im_fixed.voxel_data[end, end, 1],
        im_fixed.voxel_data[end, end, end]
    ]



    value_to_extrapolate=median(corners)
    interpolated_points=interpolate_my(points_to_interpolate,im_moving.voxel_data,old_spacing,interpolator_enum,false,value_to_extrapolate)

    new_voxel_data=reshape(interpolated_points,(new_size[1],new_size[2],new_size[3]))
    new_voxel_data=cast_to_array_b_type(new_voxel_data,im.voxel_data)


    new_im =update_voxel_and_spatial_data(im_moving, new_voxel_data
    ,im_fixed.origin,new_spacing,im_fixed.direction)


    return new_im
end


function load_image(path)
  """
  load image from path
  """
  # test_image_equality(p,p)

  medimage_instance_array = load_images(path)
  medimage_instance = medimage_instance_array[1]
  return medimage_instance
end#load_image



# debug_folder="/home/jakubmitura/projects/MedImage.jl/test_data/debug"
# p="/home/jakubmitura/projects/MedImage.jl/test_data/volume-0.nii.gz"



im_fixed=load_image("/home/jakubmitura/projects/MedImage.jl/test_data/pet_data/pat_2_sudy_0_2022-09-16_Standardized_Uptake_Value_body_weight.nii.gz")
im_moving=load_image("/home/jakubmitura/projects/MedImage.jl/test_data/pet_data/pat_2_sudy_1_2023-07-12_Standardized_Uptake_Value_body_weight.nii.gz")
resample_to_image(im_fixed, im_moving,Linear_en)



# """
# get 4 dimensional array of cartesian indicies of a 3 dimensional array
# thats size is passed as an argument dims
# """
# function get_base_indicies_arr(dims)    
#     indices = CartesianIndices(dims)
#     # indices=collect.(Tuple.(collect(indices)))
#     indices=Tuple.(collect(indices))
#     indices=collect(Iterators.flatten(indices))
#     indices=reshape(indices,(3,dims[1]*dims[2]*dims[3]))
#     indices=permutedims(indices,(1,2))
#     return indices
# end#get_base_indicies_arr



# indices=get_base_indicies_arr((4,4,4))
# origin=(2.0,2.0,2.0)
# # fixed_physical = im_fixed.origin .+ ((Tuple.(indices) .- 1).* reshape(collect(im_fixed.spacing), size(Tuple.(indices))))
# fixed_physical = origin .+ (indices)



# vv= zeros(3,3,3)
# indices = map(el->collect(el) ,collect(CartesianIndices(vv)))