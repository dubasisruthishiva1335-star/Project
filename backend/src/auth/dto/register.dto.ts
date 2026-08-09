import { IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { Transform } from 'class-transformer';

export class RegisterDto {
  @IsString() hallTicket: string;
  @IsString() fullName: string;
  @IsOptional() @IsString() email?: string;
  @IsIn(['btech', 'degree']) courseType: 'btech' | 'degree';
  @IsString() branch: string;

  @IsOptional()
  @Transform(({ value, obj }) => {
    const raw = value ?? obj.year ?? 1;
    return Number(raw);
  })
  @IsInt()
  @Min(1)
  @Max(8)
  semester?: number;

  @IsOptional()
  @Transform(({ value }) => (value !== undefined ? Number(value) : undefined))
  year?: number;

  @IsOptional() @IsString() password?: string;
}
