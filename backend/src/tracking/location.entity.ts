import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  Index,
} from 'typeorm';

@Entity('locations')
export class Location {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  driverId!: string;

  // PostGIS Point type for accurate geospatial querying
  @Index({ spatial: true })
  @Column({
    type: 'geometry',
    spatialFeatureType: 'Point',
    srid: 4326,
  })
  coordinates!: any; // e.g., { type: "Point", coordinates: [lng, lat] }

  @Column({ type: 'float', nullable: true })
  bearing!: number;

  @Column({ type: 'float', nullable: true })
  speed!: number;

  @CreateDateColumn()
  timestamp!: Date;
}
