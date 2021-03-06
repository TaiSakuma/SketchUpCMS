# Tai Sakuma <sakuma@fnal.gov>
require 'EntityDisplayer'

##__________________________________________________________________||
class EntityDisplayer
  def inspect
    "#<" + self.class.name + ":0x" + self.object_id.to_s(16) + ">"
  end
  def initialize layerName, z, x, y
    @z0, @x0, @y0  = z, x, y
    @z, @x, @y  = @z0, @x0, @y0
    model = Sketchup.active_model
    @layer = model.layers.add(model.layers.unique_name(layerName))
  end
  def clear
    @z, @x, @y  = @z0, @x0, @y0
  end
  def display instance
    instance.layer = @layer
    x = instance.bounds.height/2*1.5
    @x += x
    vector = Geom::Vector3d.new(@z + instance.bounds.width/2 - instance.bounds.center.x, @x - instance.bounds.center.y, @y + instance.bounds.depth/2*1.05)
    transformation = Geom::Transformation.translation vector
    instance.transform! transformation

    # instance.model.entities.add_text instance.definition.name, [@z, @x, 0]

    @x += x

  end
end

##__________________________________________________________________||
